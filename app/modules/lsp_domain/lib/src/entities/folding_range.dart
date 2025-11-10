import 'package:freezed_annotation/freezed_annotation.dart';

part 'folding_range.freezed.dart';

/// Folding range represents a region that can be folded in the editor.
///
/// Examples:
/// - Function bodies
/// - Class definitions
/// - Comment blocks
/// - Import sections
@freezed
class FoldingRange with _$FoldingRange {
  const factory FoldingRange({
    /// Start line (0-indexed)
    required int startLine,

    /// Optional start character (0-indexed)
    int? startCharacter,

    /// End line (0-indexed)
    required int endLine,

    /// Optional end character (0-indexed)
    int? endCharacter,

    /// Kind of folding range
    FoldingRangeKind? kind,

    /// Collapsed text to display when folded
    String? collapsedText,
  }) = _FoldingRange;
}

/// Folding range kind.
enum FoldingRangeKind {
  comment,
  imports,
  region,
  other,
}
