import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:editor_core/editor_core.dart';
import 'document_symbol.dart';

part 'type_hierarchy.freezed.dart';

/// Type hierarchy item representing a class/interface/type
@freezed
class TypeHierarchyItem with _$TypeHierarchyItem {
  const factory TypeHierarchyItem({
    required String name,
    required SymbolKind kind,
    String? detail,
    required DocumentUri uri,
    required TextSelection range,
    required TextSelection selectionRange,
  }) = _TypeHierarchyItem;
}

/// Result for type hierarchy request
@freezed
class TypeHierarchyResult with _$TypeHierarchyResult {
  const factory TypeHierarchyResult({
    required TypeHierarchyItem item,
    List<TypeHierarchyItem>? supertypes,
    List<TypeHierarchyItem>? subtypes,
  }) = _TypeHierarchyResult;
}
