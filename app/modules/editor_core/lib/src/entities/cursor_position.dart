import 'package:freezed_annotation/freezed_annotation.dart';
import '../failures/editor_failure.dart';

part 'cursor_position.freezed.dart';

/// Represents a position in the editor (0-indexed).
/// This is platform-agnostic and doesn't depend on Monaco or any specific editor.
@freezed
class CursorPosition with _$CursorPosition {
  const factory CursorPosition({
    required int line,
    required int column,
  }) = _CursorPosition;

  const CursorPosition._();

  /// Factory with validation
  factory CursorPosition.create({
    required int line,
    required int column,
  }) {
    if (line < 0) {
      throw EditorFailure.invalidPosition(message: 'Line must be >= 0, got $line');
    }
    if (column < 0) {
      throw EditorFailure.invalidPosition(message: 'Column must be >= 0, got $column');
    }
    return CursorPosition(line: line, column: column);
  }

  /// Checks if this position is before another
  bool isBefore(CursorPosition other) {
    if (line < other.line) return true;
    if (line == other.line && column < other.column) return true;
    return false;
  }

  /// Checks if this position is after another
  bool isAfter(CursorPosition other) {
    return !isBefore(other) && !isEqual(other);
  }

  /// Checks if this position is equal to another
  bool isEqual(CursorPosition other) {
    return line == other.line && column == other.column;
  }

  /// Offset the position by a number of lines/columns
  CursorPosition offset({int lines = 0, int columns = 0}) {
    return CursorPosition.create(
      line: line + lines,
      column: column + columns,
    );
  }
}
