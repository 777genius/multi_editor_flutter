import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import '../base/command.dart';

part 'uninstall_runtime_command.freezed.dart';

/// Command: Uninstall Runtime
/// Removes the VS Code runtime and all modules
@freezed
class UninstallRuntimeCommand extends Command<Unit>
    with _$UninstallRuntimeCommand {
  const factory UninstallRuntimeCommand({
    /// Specific modules to uninstall
    /// If empty, uninstalls everything
    @Default([]) List<ModuleId> moduleIds,

    /// Whether to keep downloaded files
    @Default(false) bool keepDownloads,
  }) = _UninstallRuntimeCommand;
}
