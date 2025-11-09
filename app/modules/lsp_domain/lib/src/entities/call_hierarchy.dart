import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:editor_core/editor_core.dart';
import 'document_symbol.dart';

part 'call_hierarchy.freezed.dart';

/// Call hierarchy item representing a function/method
@freezed
class CallHierarchyItem with _$CallHierarchyItem {
  const factory CallHierarchyItem({
    required String name,
    required SymbolKind kind,
    String? detail,
    required DocumentUri uri,
    required TextSelection range,
    required TextSelection selectionRange,
  }) = _CallHierarchyItem;
}

/// Result for call hierarchy request
@freezed
class CallHierarchyResult with _$CallHierarchyResult {
  const factory CallHierarchyResult({
    required CallHierarchyItem item,
    List<CallHierarchyIncomingCall>? incomingCalls,
    List<CallHierarchyOutgoingCall>? outgoingCalls,
  }) = _CallHierarchyResult;
}

/// Incoming call information
@freezed
class CallHierarchyIncomingCall with _$CallHierarchyIncomingCall {
  const factory CallHierarchyIncomingCall({
    required CallHierarchyItem from,
    required List<TextSelection> fromRanges,
  }) = _CallHierarchyIncomingCall;
}

/// Outgoing call information
@freezed
class CallHierarchyOutgoingCall with _$CallHierarchyOutgoingCall {
  const factory CallHierarchyOutgoingCall({
    required CallHierarchyItem to,
    required List<TextSelection> fromRanges,
  }) = _CallHierarchyOutgoingCall;
}
