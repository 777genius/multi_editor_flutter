import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:multi_editor_core/multi_editor_core.dart';

part 'editor_state.freezed.dart';

@freezed
sealed class EditorState with _$EditorState {
  const EditorState._();

  const factory EditorState.initial() = _Initial;

  const factory EditorState.loading() = _Loading;

  const factory EditorState.loaded({
    required FileDocument file,
    @Default(false) bool isDirty,
    @Default(false) bool isSaving,
  }) = _Loaded;

  const factory EditorState.error({required String message}) = _Error;

  bool get isInitial => this is _Initial;
  bool get isLoading => this is _Loading;
  bool get isLoaded => this is _Loaded;
  bool get isError => this is _Error;

  bool get canSave => maybeMap(
    loaded: (state) => state.isDirty && !state.isSaving,
    orElse: () => false,
  );

  String? get fileName =>
      maybeMap(loaded: (state) => state.file.name, orElse: () => null);

  String? get fileId =>
      maybeMap(loaded: (state) => state.file.id, orElse: () => null);
}
