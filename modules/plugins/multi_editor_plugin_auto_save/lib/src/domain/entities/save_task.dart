import 'package:freezed_annotation/freezed_annotation.dart';

part 'save_task.freezed.dart';
part 'save_task.g.dart';

@freezed
sealed class SaveTask with _$SaveTask {
  const SaveTask._();

  const factory SaveTask({
    required String fileId,
    required String content,
    required DateTime scheduledAt,
    @Default(false) bool completed,
    @Default(false) bool failed,
    String? errorMessage,
  }) = _SaveTask;

  factory SaveTask.fromJson(Map<String, dynamic> json) =>
      _$SaveTaskFromJson(json);

  factory SaveTask.create({required String fileId, required String content}) {
    return SaveTask(
      fileId: fileId,
      content: content,
      scheduledAt: DateTime.now(),
    );
  }

  SaveTask markCompleted() => copyWith(completed: true);

  SaveTask markFailed(String error) =>
      copyWith(failed: true, errorMessage: error);

  bool get isPending => !completed && !failed;

  bool get isCompleted => completed;

  bool get hasFailed => failed;
}
