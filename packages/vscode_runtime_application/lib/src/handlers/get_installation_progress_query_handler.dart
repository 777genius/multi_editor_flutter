import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import '../base/query_handler.dart';
import '../queries/get_installation_progress_query.dart';
import '../dtos/installation_progress_dto.dart';
import '../exceptions/application_exception.dart';

/// Handler: Get Installation Progress Query
/// Returns detailed progress information for an installation
@injectable
class GetInstallationProgressQueryHandler
    implements QueryHandler<GetInstallationProgressQuery, InstallationProgressDto> {
  final IRuntimeRepository _runtimeRepository;
  final IManifestRepository _manifestRepository;

  GetInstallationProgressQueryHandler(
    this._runtimeRepository,
    this._manifestRepository,
  );

  @override
  Future<Either<ApplicationException, InstallationProgressDto>> handle(
    GetInstallationProgressQuery query,
  ) async {
    try {
      // 1. Load modules (needed to reconstruct installation)
      final modulesResult = await _manifestRepository.fetchManifest();
      final modules = modulesResult.fold(
        (error) => throw ApplicationException(
          'Failed to load manifest: ${error.message}',
        ),
        (m) => m,
      );

      // 2. Load installation
      final installationResult = await _runtimeRepository.loadInstallation(
        query.installationId,
        modules,
      );

      final installationOption = installationResult.fold(
        (error) => throw ApplicationException(
          'Failed to load installation: ${error.message}',
        ),
        (opt) => opt,
      );

      if (installationOption.isNone()) {
        return left(const NotFoundException('Installation not found'));
      }

      final installation = installationOption.getOrElse(() => throw Exception());

      // 3. Convert to DTO
      final dto = InstallationProgressDto.fromDomain(installation);

      return right(dto);
    } on DomainException catch (e) {
      return left(ApplicationException(e.message));
    } on Exception catch (e) {
      return left(ApplicationException('Failed to get installation progress: $e', e));
    }
  }
}
