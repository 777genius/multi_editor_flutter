import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import '../base/query_handler.dart';
import '../queries/get_available_modules_query.dart';
import '../dtos/module_info_dto.dart';
import '../exceptions/application_exception.dart';

/// Handler: Get Available Modules Query
/// Returns list of available modules for installation
@injectable
class GetAvailableModulesQueryHandler
    implements QueryHandler<GetAvailableModulesQuery, List<ModuleInfoDto>> {
  final IManifestRepository _manifestRepository;
  final IRuntimeRepository _runtimeRepository;
  final IPlatformService _platformService;

  GetAvailableModulesQueryHandler(
    this._manifestRepository,
    this._runtimeRepository,
    this._platformService,
  );

  @override
  Future<Either<ApplicationException, List<ModuleInfoDto>>> handle(
    GetAvailableModulesQuery query,
  ) async {
    try {
      // 1. Get current platform
      final platformResult = await _platformService.getCurrentPlatform();
      final platform = platformResult.fold(
        (error) => throw ApplicationException(
          'Failed to detect platform: ${error.message}',
        ),
        (p) => p,
      );

      // 2. Get available modules
      List<RuntimeModule> modules;

      if (query.platformOnly) {
        final modulesResult = await _manifestRepository.getModules(platform);
        modules = modulesResult.fold(
          (error) => throw NetworkException(
            'Failed to load modules: ${error.message}',
          ),
          (m) => m,
        );
      } else {
        final modulesResult = await _manifestRepository.fetchManifest();
        modules = modulesResult.fold(
          (error) => throw NetworkException(
            'Failed to load modules: ${error.message}',
          ),
          (m) => m,
        );
      }

      // 3. Filter optional if requested
      if (!query.includeOptional) {
        modules = modules.where((m) => m.isCritical).toList();
      }

      // 4. Convert to DTOs with installation status
      final dtos = <ModuleInfoDto>[];

      for (final module in modules) {
        final isInstalledResult = await _runtimeRepository.isModuleInstalled(
          module.id,
        );
        final isInstalled = isInstalledResult.fold(
          (error) => false,
          (installed) => installed,
        );

        final dto = ModuleInfoDto.fromDomain(
          module: module,
          currentPlatform: platform,
          isInstalled: isInstalled,
        );

        dtos.add(dto);
      }

      return right(dtos);
    } on DomainException catch (e) {
      return left(ApplicationException(e.message));
    } on Exception catch (e) {
      return left(ApplicationException('Failed to get available modules: $e', e));
    }
  }
}
