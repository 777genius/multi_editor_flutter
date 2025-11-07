import 'package:freezed_annotation/freezed_annotation.dart';

part 'editor_config.freezed.dart';

@freezed
sealed class EditorConfig with _$EditorConfig {
  const EditorConfig._();

  const factory EditorConfig({
    @Default(14.0) double fontSize,
    @Default('Consolas, Monaco, monospace') String fontFamily,
    @Default(false) bool showMinimap,
    @Default(true) bool wordWrap,
    @Default(2) int tabSize,
    @Default(true) bool showLineNumbers,
    @Default(true) bool bracketPairColorization,
    @Default(true) bool showStatusBar,
    @Default(true) bool autoSave,
    @Default(2) int autoSaveDelay,
  }) = _EditorConfig;
}
