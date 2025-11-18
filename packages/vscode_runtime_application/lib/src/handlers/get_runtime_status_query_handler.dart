import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import '../base/query_handler.dart';
import '../queries/get_runtime_status_query.dart';
import '../dtos/runtime_status_dto.dart';
import '../exceptions/application_exception.dart';

/// Handler: Get Runtime Status Query
/// Returns current runtime installation status
@injectable
class GetRuntimeStatusQueryHandler
    implements QueryHandler<GetRuntimeStatusQuery, RuntimeStatusDto> {
  final IRuntimeRepository _runtimeRepository;
  final IManifestRepository _manifestRepository;

  GetRuntimeStatusQueryHandler(
    this._runtimeRepository,
    this._manifestRepository,
  );

  @override
  Future<Either<ApplicationException, RuntimeStatusDto>> handle(
    GetRuntimeStatusQuery query,
  ) async {
    try {
      // 1. Check installed version
      final versionResult = await _runtimeRepository.getInstalledVersion();
      final versionOption = versionResult.fold(
        (error) => throw ApplicationException(
          'Failed to get installed version: ${error.message}',
        ),
        (version) => version,
      );

      // 2. If not installed, return not installed status
      if (versionOption.isNone()) {
        return right(const RuntimeStatusDto.notInstalled());
      }

      final version = versionOption.getOrElse(() => throw Exception());

      // 3. Get all available modules
      final modulesResult = await _manifestRepository.fetchManifest();
      final allModules = modulesResult.fold(
        (error) => throw ApplicationException(
          'Failed to fetch manifest: ${error.message}',
        ),
        (modules) => modules,
      );

      // 4. Check which modules are installed
      final installedModules = <ModuleId>[];
      final missingModules = <ModuleId>[];

      for (final module in allModules) {
        final isInstalledResult = await _runtimeRepository.isModuleInstalled(
          module.id,
        );
        final isInstalled = isInstalledResult.fold(
          (error) => false,
          (installed) => installed,
        );

        if (isInstalled) {
          installedModules.add(module.id);
        } else if (module.isCritical) {
          // Only track missing critical modules
          missingModules.add(module.id);
        }
      }

      // 5. Determine status
      if (missingModules.isEmpty) {
        return right(RuntimeStatusDto.installed(
          version: version,
          installedAt: DateTime.now(), // Would ideally be persisted
          installedModules: installedModules,
        ));
      } else {
        return right(RuntimeStatusDto.partiallyInstalled(
          version: version,
          installedModules: installedModules,
          missingModules: missingModules,
        ));
      }
    } on DomainException catch (e) {
      return left(ApplicationException(e.message));
    } on Exception catch (e) {
      return left(ApplicationException('Failed to get runtime status: $e', e));
    }
  }
}
