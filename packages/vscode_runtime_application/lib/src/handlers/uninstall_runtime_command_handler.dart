import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import '../base/command_handler.dart';
import '../commands/uninstall_runtime_command.dart';
import '../exceptions/application_exception.dart';

/// Handler: Uninstall Runtime Command
/// Removes runtime modules from the system
@injectable
class UninstallRuntimeCommandHandler
    implements CommandHandler<UninstallRuntimeCommand, Unit> {
  final IRuntimeRepository _runtimeRepository;
  final IFileSystemService _fileSystemService;
  final IEventBus _eventBus;

  UninstallRuntimeCommandHandler(
    this._runtimeRepository,
    this._fileSystemService,
    this._eventBus,
  );

  @override
  Future<Either<ApplicationException, Unit>> handle(
    UninstallRuntimeCommand command,
  ) async {
    try {
      // 1. Get installation directory
      final installDirResult = await _fileSystemService.getInstallationDirectory();
      final installDir = installDirResult.fold(
        (error) => throw ApplicationException(
          'Failed to get installation directory: ${error.message}',
        ),
        (dir) => dir,
      );

      if (command.moduleIds.isEmpty) {
        // Uninstall everything
        final deleteResult = await _fileSystemService.deleteDirectory(installDir);

        if (deleteResult.isLeft()) {
          return left(const FileSystemException('Failed to delete installation directory'));
        }

        // Clear installation state
        await _runtimeRepository.deleteInstallation();
      } else {
        // Uninstall specific modules
        for (final moduleId in command.moduleIds) {
          final moduleDirResult = await _fileSystemService.getModuleDirectory(moduleId);

          final moduleDir = moduleDirResult.fold(
            (error) => throw ApplicationException(
              'Failed to get module directory: ${error.message}',
            ),
            (dir) => dir,
          );

          // Delete module directory
          final deleteResult = await _fileSystemService.deleteDirectory(moduleDir);

          if (deleteResult.isLeft()) {
            return left(FileSystemException(
              'Failed to delete module: ${moduleId.value}',
            ));
          }
        }
      }

      // 2. Clean up downloads if requested
      if (!command.keepDownloads) {
        final downloadDirResult = await _fileSystemService.getDownloadDirectory();

        if (downloadDirResult.isRight()) {
          final downloadDir = downloadDirResult.getOrElse(() => throw Exception());
          await _fileSystemService.deleteDirectory(downloadDir);
        }
      }

      return right(unit);
    } on DomainException catch (e) {
      return left(ApplicationException(e.message));
    } on Exception catch (e) {
      return left(ApplicationException('Failed to uninstall runtime: $e', e));
    }
  }
}
