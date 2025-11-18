import 'package:freezed_annotation/freezed_annotation.dart';
import '../base/query.dart';
import '../dtos/runtime_status_dto.dart';

part 'get_runtime_status_query.freezed.dart';

/// Query: Get Runtime Status
/// Returns the current installation status of the runtime
@freezed
class GetRuntimeStatusQuery extends Query<RuntimeStatusDto>
    with _$GetRuntimeStatusQuery {
  const factory GetRuntimeStatusQuery() = _GetRuntimeStatusQuery;
}
