import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import '../base/query_handler.dart';
import '../queries/get_platform_info_query.dart';
import '../dtos/platform_info_dto.dart';
import '../exceptions/application_exception.dart';

/// Handler: Get Platform Info Query
/// Returns information about the current platform
@injectable
class GetPlatformInfoQueryHandler
    implements QueryHandler<GetPlatformInfoQuery, PlatformInfoDto> {
  final IPlatformService _platformService;

  GetPlatformInfoQueryHandler(this._platformService);

  @override
  Future<Either<ApplicationException, PlatformInfoDto>> handle(
    GetPlatformInfoQuery query,
  ) async {
    try {
      // 1. Get platform info
      final platformInfoResult = await _platformService.getPlatformInfo();
      final platformInfo = platformInfoResult.fold(
        (error) => throw ApplicationException(
          'Failed to get platform info: ${error.message}',
        ),
        (info) => info,
      );

      // 2. Get available disk space
      final diskSpaceResult = await _platformService.getAvailableDiskSpace();
      final diskSpace = diskSpaceResult.fold(
        (error) => ByteSize.fromGB(100), // Default fallback
        (bytes) => ByteSize(bytes: bytes),
      );

      // 3. Check permissions
      final permissionsResult = await _platformService.hasRequiredPermissions();
      final hasPermissions = permissionsResult.fold(
        (error) => false,
        (has) => has,
      );

      // 4. Check if platform is supported
      final isSupportedResult = await _platformService.isPlatformSupported(
        platformInfo.identifier,
      );
      final isSupported = isSupportedResult.fold(
        (error) => false,
        (supported) => supported,
      );

      // 5. Create DTO
      final dto = PlatformInfoDto(
        identifier: platformInfo.identifier,
        osName: platformInfo.osName,
        osVersion: platformInfo.osVersion,
        architecture: platformInfo.architecture,
        numberOfProcessors: platformInfo.numberOfProcessors,
        availableDiskSpace: diskSpace,
        hasRequiredPermissions: hasPermissions,
        isSupported: isSupported,
      );

      return right(dto);
    } on DomainException catch (e) {
      return left(ApplicationException(e.message));
    } on Exception catch (e) {
      return left(ApplicationException('Failed to get platform info: $e', e));
    }
  }
}
