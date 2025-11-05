import 'package:editor_core/editor_core.dart';
import '../../domain/entities/save_task.dart';

class TriggerSaveUseCase {
  final FileRepository _fileRepository;

  TriggerSaveUseCase(this._fileRepository);

  Future<void> execute(SaveTask task) async {
    if (task.completed || task.failed) {
      throw StateError('Task is not pending');
    }

    final fileResult = await _fileRepository.load(task.fileId);

    await fileResult.fold(
      (failure) => throw Exception('Failed to load file: ${failure.displayMessage}'),
      (file) async {
        final updatedFile = file.copyWith(content: task.content);
        final saveResult = await _fileRepository.save(updatedFile);

        await saveResult.fold(
          (failure) => throw Exception('Failed to save file: ${failure.displayMessage}'),
          (_) => Future.value(),
        );
      },
    );
  }
}
