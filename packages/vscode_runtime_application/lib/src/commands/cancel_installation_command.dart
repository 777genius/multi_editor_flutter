import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import '../base/command.dart';

part 'cancel_installation_command.freezed.dart';

/// Command: Cancel Installation
/// Cancels an ongoing installation
@freezed
class CancelInstallationCommand extends Command<Unit>
    with _$CancelInstallationCommand {
  const factory CancelInstallationCommand({
    /// Installation ID to cancel
    required InstallationId installationId,

    /// Cancellation reason
    String? reason,
  }) = _CancelInstallationCommand;
}
