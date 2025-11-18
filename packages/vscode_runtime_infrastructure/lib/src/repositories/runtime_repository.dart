import 'package:dartz/dartz.dart';
import 'package:path/path.dart' as path;
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import '../data_sources/runtime_storage_data_source.dart';
import '../models/runtime_installation_dto.dart';

/// Runtime Repository Implementation
/// Manages runtime installation state persistence
class RuntimeRepository implements IRuntimeRepository {
  final RuntimeStorageDataSource _dataSource;
  final String _baseInstallPath;

  RuntimeRepository(
    this._dataSource, {
    String? baseInstallPath,
  }) : _baseInstallPath = baseInstallPath ?? '/tmp/vscode_runtime';

  @override
  Future<Either<DomainException, Unit>> saveInstallation(
    RuntimeInstallation installation,
  ) async {
    try {
      final dto = RuntimeInstallationDto.fromDomain(installation);

      await _dataSource.saveInstallation(dto);

      // If installation is completed, save the version
      if (installation.status == InstallationStatus.completed) {
        // Find the highest version from modules
        if (installation.modules.isNotEmpty) {
          final version = installation.modules.first.version;
          await _dataSource.saveInstalledVersion(version.toString());
        }

        // Mark all modules as installed
        for (final moduleId in installation.installedModules) {
          await _dataSource.markModuleInstalled(moduleId.value);
        }
      }

      return right(unit);
    } catch (e) {
      return left(
        DomainException('Failed to save installation: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<DomainException, Option<RuntimeInstallation>>> loadInstallation(
    InstallationId installationId,
    List<RuntimeModule> modules,
  ) async {
    try {
      final dto = await _dataSource.loadInstallation();

      if (dto == null) {
        return right(none());
      }

      // Only return if the ID matches
      if (dto.id != installationId.value) {
        return right(none());
      }

      // Reconstruct the installation from DTO + modules
      final installation = RuntimeInstallation(
        id: InstallationId(value: dto.id),
        modules: modules,
        targetPlatform: dto.toPlatformIdentifier(),
        status: dto.toInstallationStatus(),
        createdAt: dto.createdAt,
        trigger: dto.toInstallationTrigger(),
        installedModules: dto.installedModuleIds
            .map((id) => ModuleId(value: id))
            .toList(),
        progress: dto.progress,
        errorMessage: dto.errorMessage,
        completedAt: dto.completedAt,
        failedAt: dto.failedAt,
      );

      return right(some(installation));
    } catch (e) {
      return left(
        DomainException('Failed to load installation: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<DomainException, List<RuntimeInstallation>>> getInstallationHistory() async {
    try {
      final dtos = await _dataSource.getInstallationHistory();

      // Note: Cannot reconstruct full installations without modules
      // This is a limitation - would need to store modules separately
      // For now, return empty list
      // TODO: Implement proper history storage with modules
      return right([]);
    } catch (e) {
      return left(
        DomainException('Failed to get installation history: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<DomainException, Option<RuntimeVersion>>> getInstalledVersion() async {
    try {
      final versionString = await _dataSource.getInstalledVersion();

      if (versionString == null) {
        return right(none());
      }

      final version = RuntimeVersion.fromString(versionString);

      return right(some(version));
    } catch (e) {
      return left(
        DomainException('Failed to get installed version: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<DomainException, Unit>> saveInstalledVersion(
    RuntimeVersion version,
  ) async {
    try {
      await _dataSource.saveInstalledVersion(version.toString());
      return right(unit);
    } catch (e) {
      return left(
        DomainException('Failed to save installed version: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<DomainException, bool>> isModuleInstalled(
    ModuleId moduleId,
  ) async {
    try {
      final isInstalled = await _dataSource.isModuleInstalled(moduleId.value);

      return right(isInstalled);
    } catch (e) {
      return left(
        DomainException('Failed to check module installation: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<DomainException, String>> getInstallationDirectory() async {
    try {
      return right(_baseInstallPath);
    } catch (e) {
      return left(
        DomainException('Failed to get installation directory: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<DomainException, String>> getModuleDirectory(
    ModuleId moduleId,
  ) async {
    try {
      final modulePath = path.join(_baseInstallPath, 'modules', moduleId.value);
      return right(modulePath);
    } catch (e) {
      return left(
        DomainException('Failed to get module directory: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<DomainException, Unit>> deleteInstallation([
    InstallationId? installationId,
  ]) async {
    try {
      if (installationId != null) {
        // Delete specific installation (not implemented in storage yet)
        // For now, delete all
        await _dataSource.deleteInstallation();
      } else {
        // Delete all installations
        await _dataSource.deleteInstallation();
      }

      return right(unit);
    } catch (e) {
      return left(
        DomainException('Failed to delete installation: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<DomainException, Option<RuntimeInstallation>>> getLatestInstallation() async {
    try {
      final dto = await _dataSource.loadInstallation();

      if (dto == null) {
        return right(none());
      }

      // Note: Cannot reconstruct without modules
      // Would need modules list to reconstruct
      // For now, return none
      // TODO: Store modules with installation or pass modules parameter
      return right(none());
    } catch (e) {
      return left(
        DomainException('Failed to get latest installation: ${e.toString()}'),
      );
    }
  }
}
