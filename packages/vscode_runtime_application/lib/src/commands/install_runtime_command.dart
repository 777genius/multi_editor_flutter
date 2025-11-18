import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import '../base/command.dart';

part 'install_runtime_command.freezed.dart';

/// Command: Install VS Code Runtime
/// Installs the complete runtime with all dependencies
@freezed
class InstallRuntimeCommand extends Command<Unit>
    with _$InstallRuntimeCommand {
  const factory InstallRuntimeCommand({
    /// List of module IDs to install
    /// If empty, installs all critical modules
    @Default([]) List<ModuleId> moduleIds,

    /// Trigger that initiated the installation
    @Default(InstallationTrigger.manual) InstallationTrigger trigger,

    /// Progress callback: (moduleId, progress 0.0-1.0)
    void Function(ModuleId moduleId, double progress)? onProgress,

    /// Cancellation token
    Object? cancelToken,
  }) = _InstallRuntimeCommand;
}
