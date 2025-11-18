import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../base/command.dart';
import '../dtos/runtime_status_dto.dart';

part 'check_runtime_updates_command.freezed.dart';

/// Command: Check Runtime Updates
/// Checks for available runtime updates
@freezed
class CheckRuntimeUpdatesCommand extends Command<RuntimeStatusDto>
    with _$CheckRuntimeUpdatesCommand {
  const factory CheckRuntimeUpdatesCommand({
    /// Force check even if recently checked
    @Default(false) bool forceCheck,
  }) = _CheckRuntimeUpdatesCommand;
}
