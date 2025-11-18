import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import '../base/query.dart';
import '../dtos/installation_progress_dto.dart';

part 'get_installation_progress_query.freezed.dart';

/// Query: Get Installation Progress
/// Returns current installation progress for a specific installation
@freezed
class GetInstallationProgressQuery extends Query<InstallationProgressDto>
    with _$GetInstallationProgressQuery {
  const factory GetInstallationProgressQuery({
    required InstallationId installationId,
  }) = _GetInstallationProgressQuery;
}
