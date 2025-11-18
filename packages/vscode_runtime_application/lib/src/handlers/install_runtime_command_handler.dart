import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import '../base/command_handler.dart';
import '../commands/install_runtime_command.dart';
import '../exceptions/application_exception.dart';

/// Handler: Install Runtime Command
/// Orchestrates the complete runtime installation process
@injectable
class InstallRuntimeCommandHandler
    implements CommandHandler<InstallRuntimeCommand, Unit> {
  final IRuntimeRepository _runtimeRepository;
  final IManifestRepository _manifestRepository;
  final IDownloadService _downloadService;
  final IExtractionService _extractionService;
  final IVerificationService _verificationService;
  final IPlatformService _platformService;
  final IFileSystemService _fileSystemService;
  final IEventBus _eventBus;
  final IDependencyResolver _dependencyResolver;

  InstallRuntimeCommandHandler(
    this._runtimeRepository,
    this._manifestRepository,
    this._downloadService,
    this._extractionService,
    this._verificationService,
    this._platformService,
    this._fileSystemService,
    this._eventBus,
    this._dependencyResolver,
  );

  @override
  Future<Either<ApplicationException, Unit>> handle(
    InstallRuntimeCommand command,
  ) async {
    RuntimeInstallation? currentInstallation;
    CancelToken? cancelToken;

    try {
      // Create cancellation token if provided
      if (command.cancelToken != null) {
        cancelToken = command.cancelToken as CancelToken;
      }

      // 1. Get current platform
      final platformResult = await _platformService.getCurrentPlatform();
      final platform = platformResult.fold(
        (error) => throw ApplicationException(
          'Failed to detect platform: ${error.message}',
        ),
        (p) => p,
      );

      // 2. Load manifest and get available modules
      final modulesResult = await _manifestRepository.getModules(platform);
      final allModules = modulesResult.fold(
        (error) => throw NetworkException(
          'Failed to load module manifest: ${error.message}',
        ),
        (modules) => modules,
      );

      if (allModules.isEmpty) {
        return left(const ApplicationException(
          'No modules available for current platform',
        ));
      }

      // 3. Determine which modules to install
      List<RuntimeModule> requestedModules;

      if (command.moduleIds.isEmpty) {
        // Install all critical modules
        requestedModules = allModules.where((m) => m.isCritical).toList();
      } else {
        // Install specific modules
        requestedModules = allModules
            .where((m) => command.moduleIds.contains(m.id))
            .toList();

        if (requestedModules.length != command.moduleIds.length) {
          return left(const NotFoundException('Some requested modules not found'));
        }
      }

      // 4. Resolve dependencies and determine installation order
      final resolvedResult = _dependencyResolver.resolveOrder(requestedModules);
      final sortedModules = resolvedResult.fold(
        (error) => throw ApplicationException(
          'Failed to resolve dependencies: ${error.message}',
        ),
        (modules) => modules,
      );

      // 5. Create installation aggregate
      currentInstallation = RuntimeInstallation.create(
        modules: sortedModules,
        platform: platform,
        trigger: command.trigger,
      );

      // 6. Start installation
      currentInstallation = currentInstallation!.start();

      // Publish events
      await _publishEvents(currentInstallation);
      currentInstallation = currentInstallation.clearEvents();

      // Save initial state
      await _runtimeRepository.saveInstallation(currentInstallation);

      // 7. Install each module in order
      while (true) {
        final nextModuleOption = currentInstallation.getNextModuleToInstall();

        if (nextModuleOption.isNone()) {
          // All modules installed
          break;
        }

        final module = nextModuleOption.getOrElse(() => throw Exception());

        // Install the module
        final installResult = await _installModule(
          installation: currentInstallation,
          module: module,
          platform: platform,
          onProgress: command.onProgress,
          cancelToken: cancelToken,
        );

        currentInstallation = installResult.fold(
          (error) {
            // Mark installation as failed
            return currentInstallation!.fail(
              error.message,
              failedModule: module.id,
            );
          },
          (updatedInstallation) => updatedInstallation,
        );

        // Publish events
        await _publishEvents(currentInstallation);
        currentInstallation = currentInstallation.clearEvents();

        // Save state after each module
        await _runtimeRepository.saveInstallation(currentInstallation);

        // Check if installation failed
        if (currentInstallation.status == InstallationStatus.failed) {
          return left(ApplicationException(
            currentInstallation.errorMessage ?? 'Installation failed',
          ));
        }

        // Check if cancelled
        if (cancelToken?.isCancelled == true) {
          currentInstallation = currentInstallation.cancel(
            reason: 'Cancelled by user',
          );
          await _publishEvents(currentInstallation);
          await _runtimeRepository.saveInstallation(currentInstallation);

          return left(const OperationCancelledException());
        }
      }

      return right(unit);
    } on DomainException catch (e) {
      return left(ApplicationException(e.message));
    } on DioException catch (e) {
      return left(NetworkException('Network error: ${e.message}', e));
    } on FileSystemException catch (e) {
      return left(ApplicationException('File system error: ${e.message}', e));
    } on Exception catch (e) {
      return left(ApplicationException('Unexpected error: $e', e));
    }
  }

  /// Install a single module
  Future<Either<ApplicationException, RuntimeInstallation>> _installModule({
    required RuntimeInstallation installation,
    required RuntimeModule module,
    required PlatformIdentifier platform,
    void Function(ModuleId, double)? onProgress,
    CancelToken? cancelToken,
  }) async {
    var current = installation;

    try {
      // 1. Get artifact for current platform
      final artifactOption = module.artifactFor(platform);
      if (artifactOption.isNone()) {
        return left(ApplicationException(
          'No artifact available for platform: ${platform.toDisplayString()}',
        ));
      }
      final artifact = artifactOption.getOrElse(() => throw Exception());

      // 2. Get download directory
      final downloadDirResult = await _fileSystemService.getDownloadDirectory();
      final downloadDir = downloadDirResult.fold(
        (error) => throw FileSystemException(
          'Failed to get download directory: ${error.message}',
        ),
        (dir) => dir,
      );

      // 3. Download artifact
      current = current.markModuleDownloadStarted(module.id);
      onProgress?.call(module.id, 0.0);

      final targetPath = '${downloadDir.path}/${artifact.url.filename}';

      final downloadResult = await _downloadService.download(
        url: artifact.url,
        targetPath: targetPath,
        onProgress: (downloaded, total) {
          final progress = downloaded.progressTo(total);
          onProgress?.call(module.id, progress * 0.6); // 60% for download
        },
        cancelToken: cancelToken,
      );

      final downloadedFile = downloadResult.fold(
        (error) => throw NetworkException(
          'Download failed: ${error.message}',
        ),
        (file) => file,
      );

      current = current.markModuleDownloaded(module.id);
      onProgress?.call(module.id, 0.6);

      // 4. Verify integrity
      current = current.markModuleVerified(module.id);

      final verifyResult = await _verificationService.verify(
        file: downloadedFile,
        expectedHash: artifact.hash,
        expectedSize: artifact.size,
      );

      if (verifyResult.isLeft()) {
        return left(ApplicationException(
          'Verification failed for ${module.name}',
        ));
      }

      current = current.markModuleVerified(module.id);
      onProgress?.call(module.id, 0.7);

      // 5. Extract archive
      final moduleDirResult = await _fileSystemService.getModuleDirectory(module.id);
      final moduleDir = moduleDirResult.fold(
        (error) => throw FileSystemException(
          'Failed to get module directory: ${error.message}',
        ),
        (dir) => dir,
      );

      current = current.markModuleExtractionStarted(module.id);

      final extractResult = await _extractionService.extract(
        archiveFile: downloadedFile,
        targetDirectory: moduleDir.path,
        onProgress: (extractProgress) {
          onProgress?.call(module.id, 0.7 + extractProgress * 0.3); // 30% for extraction
        },
      );

      if (extractResult.isLeft()) {
        return left(ApplicationException(
          'Extraction failed for ${module.name}',
        ));
      }

      // 6. Mark as installed
      current = current.markModuleInstalled(module.id);
      onProgress?.call(module.id, 1.0);

      // 7. Cleanup: Delete downloaded archive
      try {
        if (await downloadedFile.exists()) {
          await downloadedFile.delete();
        }
      } catch (_) {
        // Ignore cleanup errors
      }

      return right(current);
    } on DomainException catch (e) {
      return left(ApplicationException(e.message));
    } on Exception catch (e) {
      return left(ApplicationException(
        'Failed to install module ${module.name}: $e',
        e,
      ));
    }
  }

  /// Publish all uncommitted events
  Future<void> _publishEvents(RuntimeInstallation installation) async {
    for (final event in installation.uncommittedEvents) {
      await _eventBus.publish(event);
    }
  }
}
