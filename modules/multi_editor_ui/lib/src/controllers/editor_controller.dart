import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import '../state/editor_state.dart';

class EditorController extends ValueNotifier<EditorState> {
  final FileRepository _fileRepository;
  final EventBus _eventBus;
  StreamSubscription? _fileWatchSubscription;

  EditorController({
    required FileRepository fileRepository,
    required EventBus eventBus,
  }) : _fileRepository = fileRepository,
       _eventBus = eventBus,
       super(const EditorState.initial());

  Future<void> loadFile(String fileId) async {
    value = const EditorState.loading();

    try {
      final result = await _fileRepository.load(fileId);

      result.fold(
        (failure) {
          value = EditorState.error(message: failure.displayMessage);
        },
        (file) {
          value = EditorState.loaded(file: file);

          _eventBus.publish(EditorEvent.fileOpened(file: file));

          _fileWatchSubscription?.cancel();
          _fileWatchSubscription = _fileRepository.watch(fileId).listen((
            watchResult,
          ) {
            watchResult.fold(
              (failure) {
                // Log error but don't update state
              },
              (updatedFile) {
                value.mapOrNull(
                  loaded: (state) {
                    if (!state.isDirty) {
                      value = state.copyWith(file: updatedFile);
                    }
                  },
                );
              },
            );
          });
        },
      );
    } catch (e) {
      value = EditorState.error(message: 'Unexpected error: $e');
    }
  }

  void updateContent(String newContent) {
    value.mapOrNull(
      loaded: (state) {
        final updated = state.file.updateContent(newContent);
        value = state.copyWith(file: updated, isDirty: true);

        _eventBus.publish(
          EditorEvent.fileContentChanged(
            fileId: state.file.id,
            content: newContent,
          ),
        );
      },
    );
  }

  Future<void> save() async {
    await value.mapOrNull(
      loaded: (state) async {
        if (!state.isDirty) return;

        try {
          value = state.copyWith(isSaving: true);

          final result = await _fileRepository.save(state.file);

          result.fold(
            (failure) {
              value = EditorState.error(
                message: 'Save failed: ${failure.displayMessage}',
              );
            },
            (_) {
              value = state.copyWith(isDirty: false, isSaving: false);

              _eventBus.publish(EditorEvent.fileSaved(file: state.file));
            },
          );
        } catch (e) {
          value = EditorState.error(message: 'Save failed: $e');
        }
      },
    );
  }

  void close() {
    value.mapOrNull(
      loaded: (state) {
        _fileWatchSubscription?.cancel();
        _eventBus.publish(EditorEvent.fileClosed(fileId: state.file.id));
        value = const EditorState.initial();
      },
    );
  }

  @override
  void dispose() {
    _fileWatchSubscription?.cancel();
    super.dispose();
  }
}
