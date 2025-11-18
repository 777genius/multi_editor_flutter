import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import '../base/command_handler.dart';
import '../commands/check_runtime_updates_command.dart';
import '../dtos/runtime_status_dto.dart';
import '../exceptions/application_exception.dart';

/// Handler: Check Runtime Updates Command
/// Checks if a newer version of the runtime is available
@injectable
class CheckRuntimeUpdatesCommandHandler
    implements CommandHandler<CheckRuntimeUpdatesCommand, RuntimeStatusDto> {
  final IRuntimeRepository _runtimeRepository;
  final IManifestRepository _manifestRepository;

  CheckRuntimeUpdatesCommandHandler(
    this._runtimeRepository,
    this._manifestRepository,
  );

  @override
  Future<Either<ApplicationException, RuntimeStatusDto>> handle(
    CheckRuntimeUpdatesCommand command,
  ) async {
    try {
      // 1. Get currently installed version
      final installedVersionResult = await _runtimeRepository.getInstalledVersion();
      final installedVersionOption = installedVersionResult.fold(
        (error) => throw ApplicationException(
          'Failed to get installed version: ${error.message}',
        ),
        (version) => version,
      );

      if (installedVersionOption.isNone()) {
        return right(const RuntimeStatusDto.notInstalled());
      }

      final installedVersion = installedVersionOption.getOrElse(() => throw Exception());

      // 2. Fetch latest manifest
      final manifestResult = await _manifestRepository.fetchManifest();
      final latestModules = manifestResult.fold(
        (error) => throw NetworkException(
          'Failed to fetch manifest: ${error.message}',
        ),
        (modules) => modules,
      );

      if (latestModules.isEmpty) {
        return left(const ApplicationException('No modules in manifest'));
      }

      // 3. Get latest version (from first module)
      final latestVersion = latestModules.first.version;

      // 4. Compare versions
      if (latestVersion.isNewerThan(installedVersion)) {
        return right(RuntimeStatusDto.updateAvailable(
          currentVersion: installedVersion,
          availableVersion: latestVersion,
        ));
      }

      // 5. Return current status
      final installedModulesResult = await _getInstalledModules(latestModules);

      return installedModulesResult.fold(
        (error) => left(error),
        (installedModules) {
          return right(RuntimeStatusDto.installed(
            version: installedVersion,
            installedAt: DateTime.now(), // Would need to be persisted
            installedModules: installedModules,
          ));
        },
      );
    } on DomainException catch (e) {
      return left(ApplicationException(e.message));
    } on Exception catch (e) {
      return left(ApplicationException('Failed to check for updates: $e', e));
    }
  }

  /// Get list of installed modules
  Future<Either<ApplicationException, List<ModuleId>>> _getInstalledModules(
    List<RuntimeModule> allModules,
  ) async {
    final installedModules = <ModuleId>[];

    for (final module in allModules) {
      final isInstalledResult = await _runtimeRepository.isModuleInstalled(module.id);
      final isInstalled = isInstalledResult.fold(
        (error) => false,
        (installed) => installed,
      );

      if (isInstalled) {
        installedModules.add(module.id);
      }
    }

    return right(installedModules);
  }
}
