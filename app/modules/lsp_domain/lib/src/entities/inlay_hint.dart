import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:editor_core/editor_core.dart';
import 'location.dart';

part 'inlay_hint.freezed.dart';

/// Inlay hints provide inline annotations in the editor.
///
/// Examples:
/// - Type annotations: `let x = 5` → `let x: i32 = 5`
/// - Parameter names: `foo(true)` → `foo(enabled: true)`
@freezed
class InlayHint with _$InlayHint {
  const factory InlayHint({
    /// Position where hint is displayed
    required CursorPosition position,

    /// Label text or parts
    required InlayHintLabel label,

    /// Hint kind (type, parameter, etc.)
    InlayHintKind? kind,

    /// Tooltip on hover
    String? tooltip,

    /// Whether hint can be interacted with
    @Default(false) bool paddingLeft,
    @Default(false) bool paddingRight,

    /// Data for resolve
    dynamic data,
  }) = _InlayHint;
}

/// Inlay hint label (string or parts).
@freezed
class InlayHintLabel with _$InlayHintLabel {
  const factory InlayHintLabel.string(String value) = _InlayHintLabelString;
  const factory InlayHintLabel.parts(List<InlayHintLabelPart> parts) = _InlayHintLabelParts;
}

/// Part of an inlay hint label.
@freezed
class InlayHintLabelPart with _$InlayHintLabelPart {
  const factory InlayHintLabelPart({
    required String value,
    String? tooltip,
    Location? location,
  }) = _InlayHintLabelPart;
}

/// Inlay hint kind.
enum InlayHintKind {
  type,
  parameter,
  other,
}
