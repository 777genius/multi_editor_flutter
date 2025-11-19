import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo_item.freezed.dart';
part 'todo_item.g.dart';

/// Type of TODO marker
enum TodoType {
  @JsonValue('TODO')
  todo,
  @JsonValue('FIXME')
  fixme,
  @JsonValue('HACK')
  hack,
  @JsonValue('NOTE')
  note,
  @JsonValue('XXX')
  xxx,
  @JsonValue('BUG')
  bug,
  @JsonValue('OPTIMIZE')
  optimize,
  @JsonValue('REVIEW')
  review,
}

/// Priority level
enum TodoPriority {
  high,
  medium,
  low,
}

/// Position in source code
@freezed
class Position with _$Position {
  const factory Position({
    required int line,
    required int column,
  }) = _Position;

  factory Position.fromJson(Map<String, dynamic> json) =>
      _$PositionFromJson(json);
}

/// A TODO item found in source code
@freezed
class TodoItem with _$TodoItem {
  const factory TodoItem({
    required TodoType todoType,
    required TodoPriority priority,
    required String text,
    required int line,
    required int column,
    required Position position,
    String? author,
    @Default([]) List<String> tags,
  }) = _TodoItem;

  factory TodoItem.fromJson(Map<String, dynamic> json) =>
      _$TodoItemFromJson(json);
}

/// Collection of TODO items
@freezed
class TodoCollection with _$TodoCollection {
  const factory TodoCollection({
    required List<TodoItem> items,
    required TodoTypeCounts countsByType,
    required PriorityCounts countsByPriority,
    required int scanDurationMs,
  }) = _TodoCollection;

  factory TodoCollection.fromJson(Map<String, dynamic> json) =>
      _$TodoCollectionFromJson(json);
}

/// Counts by type
@freezed
class TodoTypeCounts with _$TodoTypeCounts {
  const factory TodoTypeCounts({
    @Default(0) int todo,
    @Default(0) int fixme,
    @Default(0) int hack,
    @Default(0) int note,
    @Default(0) int xxx,
    @Default(0) int bug,
    @Default(0) int optimize,
    @Default(0) int review,
  }) = _TodoTypeCounts;

  const TodoTypeCounts._();

  int get total => todo + fixme + hack + note + xxx + bug + optimize + review;

  factory TodoTypeCounts.fromJson(Map<String, dynamic> json) =>
      _$TodoTypeCountsFromJson(json);
}

/// Counts by priority
@freezed
class PriorityCounts with _$PriorityCounts {
  const factory PriorityCounts({
    @Default(0) int high,
    @Default(0) int medium,
    @Default(0) int low,
  }) = _PriorityCounts;

  factory PriorityCounts.fromJson(Map<String, dynamic> json) =>
      _$PriorityCountsFromJson(json);
}
