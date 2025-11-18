import 'package:freezed_annotation/freezed_annotation.dart';
import '../base/query.dart';
import '../dtos/module_info_dto.dart';

part 'get_available_modules_query.freezed.dart';

/// Query: Get Available Modules
/// Returns list of available modules for current platform
@freezed
class GetAvailableModulesQuery extends Query<List<ModuleInfoDto>>
    with _$GetAvailableModulesQuery {
  const factory GetAvailableModulesQuery({
    /// Whether to include optional modules
    @Default(true) bool includeOptional,

    /// Whether to only show modules compatible with current platform
    @Default(true) bool platformOnly,
  }) = _GetAvailableModulesQuery;
}
