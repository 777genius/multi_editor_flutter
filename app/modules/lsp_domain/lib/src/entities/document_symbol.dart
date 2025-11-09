import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:editor_core/editor_core.dart';

part 'document_symbol.freezed.dart';

/// Symbol information in a document (functions, classes, variables, etc.)
@freezed
class DocumentSymbol with _$DocumentSymbol {
  const factory DocumentSymbol({
    required String name,
    String? detail,
    required SymbolKind kind,
    required TextSelection range,
    required TextSelection selectionRange,
    List<DocumentSymbol>? children,
  }) = _DocumentSymbol;
}

/// Workspace-wide symbol information
@freezed
class WorkspaceSymbol with _$WorkspaceSymbol {
  const factory WorkspaceSymbol({
    required String name,
    required SymbolKind kind,
    required DocumentUri location,
    String? containerName,
  }) = _WorkspaceSymbol;
}

/// Kind of symbol
enum SymbolKind {
  file,
  module,
  namespace,
  package,
  class_,
  method,
  property,
  field,
  constructor,
  enum_,
  interface,
  function,
  variable,
  constant,
  string,
  number,
  boolean,
  array,
  object,
  key,
  null_,
  enumMember,
  struct,
  event,
  operator,
  typeParameter,
}
