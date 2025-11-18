import 'package:freezed_annotation/freezed_annotation.dart';
import '../base/query.dart';
import '../dtos/platform_info_dto.dart';

part 'get_platform_info_query.freezed.dart';

/// Query: Get Platform Info
/// Returns information about the current platform
@freezed
class GetPlatformInfoQuery extends Query<PlatformInfoDto>
    with _$GetPlatformInfoQuery {
  const factory GetPlatformInfoQuery() = _GetPlatformInfoQuery;
}
