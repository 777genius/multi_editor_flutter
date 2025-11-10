import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';

/// Mappers for converting between LSP JSON protocol and Domain models.
///
/// These mappers isolate LSP protocol details from the domain layer.
/// The domain layer works with clean, immutable domain models while
/// the infrastructure handles the messy JSON protocol.
///
/// Follows SRP: One responsibility - protocol translation.
///
/// Example:
/// ```dart
/// // LSP JSON → Domain
/// final position = LspProtocolMappers.toDomainPosition(lspJson);
///
/// // Domain → LSP JSON
/// final lspJson = LspProtocolMappers.fromDomainPosition(position);
/// ```
class LspProtocolMappers {
  // ================================================================
  // Position Mapping
  // ================================================================

  /// Converts LSP position to domain CursorPosition.
  ///
  /// LSP uses 0-indexed lines and characters.
  /// Our domain also uses 0-indexed, so direct mapping.
  ///
  /// LSP format:
  /// ```json
  /// {"line": 10, "character": 5}
  /// ```
  static CursorPosition toDomainPosition(Map<String, dynamic> json) {
    return CursorPosition.create(
      line: json['line'] as int,
      column: json['character'] as int,
    );
  }

  /// Converts domain CursorPosition to LSP position.
  static Map<String, dynamic> fromDomainPosition(CursorPosition position) {
    return {
      'line': position.line,
      'character': position.column,
    };
  }

  // ================================================================
  // Range Mapping
  // ================================================================

  /// Converts LSP range to domain TextSelection.
  ///
  /// LSP format:
  /// ```json
  /// {
  ///   "start": {"line": 0, "character": 0},
  ///   "end": {"line": 0, "character": 10}
  /// }
  /// ```
  static TextSelection toDomainRange(Map<String, dynamic> json) {
    final start = toDomainPosition(json['start'] as Map<String, dynamic>);
    final end = toDomainPosition(json['end'] as Map<String, dynamic>);

    return TextSelection(start: start, end: end);
  }

  /// Converts domain TextSelection to LSP range.
  static Map<String, dynamic> fromDomainRange(TextSelection selection) {
    return {
      'start': fromDomainPosition(selection.start),
      'end': fromDomainPosition(selection.end),
    };
  }

  // ================================================================
  // TextDocument Identifier Mapping
  // ================================================================

  /// Creates LSP TextDocumentIdentifier from domain DocumentUri.
  static Map<String, dynamic> toTextDocumentIdentifier(DocumentUri uri) {
    return {'uri': uri.value};
  }

  /// Creates LSP VersionedTextDocumentIdentifier.
  static Map<String, dynamic> toVersionedTextDocumentIdentifier(
    DocumentUri uri, {
    int? version,
  }) {
    return {
      'uri': uri.value,
      'version': version,
    };
  }

  /// Creates LSP TextDocumentItem (for didOpen).
  static Map<String, dynamic> toTextDocumentItem({
    required DocumentUri uri,
    required LanguageId languageId,
    required String text,
    int version = 1,
  }) {
    return {
      'uri': uri.value,
      'languageId': languageId.value,
      'version': version,
      'text': text,
    };
  }

  // ================================================================
  // Completion Mapping
  // ================================================================

  /// Converts LSP completion list to domain CompletionList.
  ///
  /// LSP format:
  /// ```json
  /// {
  ///   "isIncomplete": false,
  ///   "items": [...]
  /// }
  /// ```
  static CompletionList toDomainCompletionList(Map<String, dynamic> json) {
    final items = (json['items'] as List?)?.map((item) {
      return toDomainCompletionItem(item as Map<String, dynamic>);
    }).toList() ?? [];

    return CompletionList(
      items: items,
      isIncomplete: json['isIncomplete'] as bool? ?? false,
    );
  }

  /// Converts LSP completion item to domain CompletionItem.
  static CompletionItem toDomainCompletionItem(Map<String, dynamic> json) {
    return CompletionItem(
      label: json['label'] as String,
      kind: _toCompletionItemKind(json['kind'] as int?),
      detail: json['detail'] as String?,
      documentation: _extractDocumentation(json['documentation']),
      insertText: json['insertText'] as String?,
      sortText: json['sortText'] as String?,
      filterText: json['filterText'] as String?,
      preselect: json['preselect'] as bool? ?? false,
    );
  }

  /// Converts LSP completion item kind to domain enum.
  static CompletionItemKind _toCompletionItemKind(int? kind) {
    if (kind == null) return CompletionItemKind.text;

    return switch (kind) {
      1 => CompletionItemKind.text,
      2 => CompletionItemKind.method,
      3 => CompletionItemKind.function,
      4 => CompletionItemKind.constructor,
      5 => CompletionItemKind.field,
      6 => CompletionItemKind.variable,
      7 => CompletionItemKind.class_,
      8 => CompletionItemKind.interface,
      9 => CompletionItemKind.module,
      10 => CompletionItemKind.property,
      14 => CompletionItemKind.keyword,
      15 => CompletionItemKind.snippet,
      _ => CompletionItemKind.text,
    };
  }

  /// Extracts documentation from LSP format.
  ///
  /// Can be string or MarkupContent object.
  static String? _extractDocumentation(dynamic doc) {
    if (doc == null) return null;

    if (doc is String) {
      return doc;
    }

    if (doc is Map<String, dynamic>) {
      return doc['value'] as String?;
    }

    return null;
  }

  // ================================================================
  // Diagnostic Mapping
  // ================================================================

  /// Converts LSP diagnostic to domain Diagnostic.
  static Diagnostic toDomainDiagnostic(Map<String, dynamic> json) {
    return Diagnostic(
      range: toDomainRange(json['range'] as Map<String, dynamic>),
      severity: _toDiagnosticSeverity(json['severity'] as int?),
      message: json['message'] as String,
      code: json['code']?.toString(),
      source: json['source'] as String?,
    );
  }

  /// Converts LSP severity to domain enum.
  static DiagnosticSeverity _toDiagnosticSeverity(int? severity) {
    if (severity == null) return DiagnosticSeverity.information;

    return switch (severity) {
      1 => DiagnosticSeverity.error,
      2 => DiagnosticSeverity.warning,
      3 => DiagnosticSeverity.information,
      4 => DiagnosticSeverity.hint,
      _ => DiagnosticSeverity.information,
    };
  }

  // ================================================================
  // Hover Mapping
  // ================================================================

  /// Converts LSP hover to domain HoverInfo.
  static HoverInfo toDomainHoverInfo(Map<String, dynamic>? json) {
    if (json == null) {
      return HoverInfo.empty;
    }

    final contents = _extractHoverContents(json['contents']);
    final range = json['range'] != null
        ? toDomainRange(json['range'] as Map<String, dynamic>)
        : null;

    return HoverInfo(
      contents: contents,
      range: range,
    );
  }

  /// Extracts hover contents from various LSP formats.
  static String _extractHoverContents(dynamic contents) {
    if (contents is String) {
      return contents;
    }

    if (contents is Map<String, dynamic>) {
      return contents['value'] as String? ?? '';
    }

    if (contents is List) {
      return contents
          .map((item) => _extractHoverContents(item))
          .where((text) => text.isNotEmpty)
          .join('\n\n');
    }

    return '';
  }

  // ================================================================
  // Location Mapping
  // ================================================================

  /// Converts LSP location to domain Location.
  static Location toDomainLocation(Map<String, dynamic> json) {
    return Location(
      uri: DocumentUri(json['uri'] as String),
      range: toDomainRange(json['range'] as Map<String, dynamic>),
    );
  }

  /// Converts list of LSP locations to domain locations.
  static List<Location> toDomainLocations(List<dynamic>? json) {
    if (json == null) return [];

    return json
        .map((item) => toDomainLocation(item as Map<String, dynamic>))
        .toList();
  }
}

  // ================================================================
  // Code Action Mapping
  // ================================================================

  /// Converts list of LSP code actions to domain CodeActions.
  static List<CodeAction> toDomainCodeActions(List<dynamic>? json) {
    if (json == null) return [];

    return json
        .map((item) => _toDomainCodeAction(item as Map<String, dynamic>))
        .toList();
  }

  /// Converts single LSP code action to domain CodeAction.
  static CodeAction _toDomainCodeAction(Map<String, dynamic> json) {
    return CodeAction(
      title: json['title'] as String,
      kind: _toCodeActionKind(json['kind'] as String?),
      diagnostics: (json['diagnostics'] as List?)
          ?.map((d) => toDomainDiagnostic(d as Map<String, dynamic>))
          .toList(),
      edit: json['edit'] != null
          ? toDomainWorkspaceEdit(json['edit'] as Map<String, dynamic>)
          : null,
      command: json['command'] != null
          ? _toDomainCommand(json['command'] as Map<String, dynamic>)
          : null,
      isPreferred: json['isPreferred'] as bool? ?? false,
    );
  }

  /// Converts LSP code action kind string to domain enum.
  static CodeActionKind _toCodeActionKind(String? kind) {
    if (kind == null) return CodeActionKind.other;

    if (kind == 'quickfix') return CodeActionKind.quickFix;
    if (kind == 'refactor') return CodeActionKind.refactor;
    if (kind.startsWith('refactor.extract')) return CodeActionKind.refactorExtract;
    if (kind.startsWith('refactor.inline')) return CodeActionKind.refactorInline;
    if (kind.startsWith('refactor.rewrite')) return CodeActionKind.refactorRewrite;
    if (kind == 'source') return CodeActionKind.source;
    if (kind == 'source.organizeImports') return CodeActionKind.sourceOrganizeImports;

    return CodeActionKind.other;
  }

  /// Converts LSP command to domain Command.
  static Command _toDomainCommand(Map<String, dynamic> json) {
    return Command(
      title: json['title'] as String,
      command: json['command'] as String,
      arguments: json['arguments'] as List<dynamic>?,
    );
  }

  /// Converts domain diagnostic to LSP diagnostic.
  static Map<String, dynamic> fromDomainDiagnostic(Diagnostic diagnostic) {
    return {
      'range': fromDomainRange(diagnostic.range),
      'severity': _fromDiagnosticSeverity(diagnostic.severity),
      'message': diagnostic.message,
      if (diagnostic.code != null) 'code': diagnostic.code,
      if (diagnostic.source != null) 'source': diagnostic.source,
    };
  }

  /// Converts domain severity to LSP severity int.
  static int _fromDiagnosticSeverity(DiagnosticSeverity severity) {
    return switch (severity) {
      DiagnosticSeverity.error => 1,
      DiagnosticSeverity.warning => 2,
      DiagnosticSeverity.information => 3,
      DiagnosticSeverity.hint => 4,
    };
  }

  // ================================================================
  // Workspace Edit Mapping
  // ================================================================

  /// Converts LSP workspace edit to domain WorkspaceEdit.
  static WorkspaceEdit toDomainWorkspaceEdit(Map<String, dynamic> json) {
    final changesJson = json['changes'] as Map<String, dynamic>?;
    if (changesJson == null) {
      return const WorkspaceEdit(changes: {});
    }

    final changes = <DocumentUri, List<TextEdit>>{};
    changesJson.forEach((uri, edits) {
      final textEdits = (edits as List)
          .map((e) => _toDomainTextEdit(e as Map<String, dynamic>))
          .toList();
      changes[DocumentUri(uri)] = textEdits;
    });

    return WorkspaceEdit(changes: changes);
  }

  /// Converts LSP text edit to domain TextEdit.
  static TextEdit _toDomainTextEdit(Map<String, dynamic> json) {
    return TextEdit(
      range: toDomainRange(json['range'] as Map<String, dynamic>),
      newText: json['newText'] as String,
    );
  }

  /// Converts list of LSP text edits to domain TextEdits.
  static List<TextEdit> toDomainTextEdits(List<dynamic>? json) {
    if (json == null) return [];

    return json
        .map((item) => _toDomainTextEdit(item as Map<String, dynamic>))
        .toList();
  }

  // ================================================================
  // Signature Help Mapping
  // ================================================================

  /// Converts LSP signature help to domain SignatureHelp.
  static SignatureHelp toDomainSignatureHelp(Map<String, dynamic>? json) {
    if (json == null) return SignatureHelp.empty;

    final signatures = (json['signatures'] as List?)
        ?.map((s) => _toDomainSignatureInformation(s as Map<String, dynamic>))
        .toList() ?? [];

    return SignatureHelp(
      signatures: signatures,
      activeSignature: json['activeSignature'] as int?,
      activeParameter: json['activeParameter'] as int?,
    );
  }

  /// Converts LSP signature information to domain.
  static SignatureInformation _toDomainSignatureInformation(Map<String, dynamic> json) {
    final parameters = (json['parameters'] as List?)
        ?.map((p) => _toDomainParameterInformation(p as Map<String, dynamic>))
        .toList();

    return SignatureInformation(
      label: json['label'] as String,
      documentation: _extractDocumentation(json['documentation']),
      parameters: parameters,
      activeParameter: json['activeParameter'] as int?,
    );
  }

  /// Converts LSP parameter information to domain.
  static ParameterInformation _toDomainParameterInformation(Map<String, dynamic> json) {
    return ParameterInformation(
      label: json['label'] as String,
      documentation: _extractDocumentation(json['documentation']),
    );
  }

  // ================================================================
  // Formatting Options Mapping
  // ================================================================

  /// Converts domain formatting options to LSP format.
  static Map<String, dynamic> fromDomainFormattingOptions(FormattingOptions options) {
    return {
      'tabSize': options.tabSize,
      'insertSpaces': options.insertSpaces,
      if (options.trimTrailingWhitespace != null)
        'trimTrailingWhitespace': options.trimTrailingWhitespace,
      if (options.insertFinalNewline != null)
        'insertFinalNewline': options.insertFinalNewline,
      if (options.trimFinalNewlines != null)
        'trimFinalNewlines': options.trimFinalNewlines,
    };
  }

  // ================================================================
  // Document Symbol Mapping
  // ================================================================

  /// Converts list of LSP document symbols to domain.
  static List<DocumentSymbol> toDomainDocumentSymbols(List<dynamic>? json) {
    if (json == null) return [];

    return json
        .map((item) => _toDomainDocumentSymbol(item as Map<String, dynamic>))
        .toList();
  }

  /// Converts single LSP document symbol to domain.
  static DocumentSymbol _toDomainDocumentSymbol(Map<String, dynamic> json) {
    final children = (json['children'] as List?)
        ?.map((c) => _toDomainDocumentSymbol(c as Map<String, dynamic>))
        .toList();

    return DocumentSymbol(
      name: json['name'] as String,
      detail: json['detail'] as String?,
      kind: _toSymbolKind(json['kind'] as int),
      range: toDomainRange(json['range'] as Map<String, dynamic>),
      selectionRange: toDomainRange(json['selectionRange'] as Map<String, dynamic>),
      children: children,
    );
  }

  /// Converts LSP symbol kind int to domain enum.
  static SymbolKind _toSymbolKind(int kind) {
    return switch (kind) {
      1 => SymbolKind.file,
      2 => SymbolKind.module,
      3 => SymbolKind.namespace,
      4 => SymbolKind.package,
      5 => SymbolKind.class_,
      6 => SymbolKind.method,
      7 => SymbolKind.property,
      8 => SymbolKind.field,
      9 => SymbolKind.constructor,
      10 => SymbolKind.enum_,
      11 => SymbolKind.interface,
      12 => SymbolKind.function,
      13 => SymbolKind.variable,
      14 => SymbolKind.constant,
      _ => SymbolKind.variable,
    };
  }

  /// Converts list of LSP workspace symbols to domain.
  static List<WorkspaceSymbol> toDomainWorkspaceSymbols(List<dynamic>? json) {
    if (json == null) return [];

    return json
        .map((item) => _toDomainWorkspaceSymbol(item as Map<String, dynamic>))
        .toList();
  }

  /// Converts single LSP workspace symbol to domain.
  static WorkspaceSymbol _toDomainWorkspaceSymbol(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>;
    
    return WorkspaceSymbol(
      name: json['name'] as String,
      kind: _toSymbolKind(json['kind'] as int),
      location: DocumentUri(location['uri'] as String),
      containerName: json['containerName'] as String?,
    );
  }

  // ================================================================
  // Call Hierarchy Mapping
  // ================================================================

  /// Converts LSP call hierarchy item to domain (handles array or null).
  static CallHierarchyItem? toDomainCallHierarchyItem(List<dynamic>? json) {
    if (json == null || json.isEmpty) return null;
    return _toDomainCallHierarchyItemSingle(json.first as Map<String, dynamic>);
  }

  /// Converts single LSP call hierarchy item to domain.
  static CallHierarchyItem _toDomainCallHierarchyItemSingle(Map<String, dynamic> json) {
    return CallHierarchyItem(
      name: json['name'] as String,
      kind: _toSymbolKind(json['kind'] as int),
      detail: json['detail'] as String?,
      uri: DocumentUri(json['uri'] as String),
      range: toDomainRange(json['range'] as Map<String, dynamic>),
      selectionRange: toDomainRange(json['selectionRange'] as Map<String, dynamic>),
    );
  }

  /// Converts domain call hierarchy item to LSP format.
  static Map<String, dynamic> fromDomainCallHierarchyItem(CallHierarchyItem item) {
    return {
      'name': item.name,
      'kind': _fromSymbolKind(item.kind),
      if (item.detail != null) 'detail': item.detail,
      'uri': item.uri.value,
      'range': fromDomainRange(item.range),
      'selectionRange': fromDomainRange(item.selectionRange),
    };
  }

  /// Converts domain symbol kind to LSP int.
  static int _fromSymbolKind(SymbolKind kind) {
    return switch (kind) {
      SymbolKind.file => 1,
      SymbolKind.module => 2,
      SymbolKind.namespace => 3,
      SymbolKind.package => 4,
      SymbolKind.class_ => 5,
      SymbolKind.method => 6,
      SymbolKind.property => 7,
      SymbolKind.field => 8,
      SymbolKind.constructor => 9,
      SymbolKind.enum_ => 10,
      SymbolKind.interface => 11,
      SymbolKind.function => 12,
      SymbolKind.variable => 13,
      SymbolKind.constant => 14,
      _ => 13,
    };
  }

  /// Converts list of LSP incoming calls to domain.
  static List<CallHierarchyIncomingCall> toDomainIncomingCalls(List<dynamic>? json) {
    if (json == null) return [];

    return json
        .map((item) => _toDomainIncomingCall(item as Map<String, dynamic>))
        .toList();
  }

  /// Converts single LSP incoming call to domain.
  static CallHierarchyIncomingCall _toDomainIncomingCall(Map<String, dynamic> json) {
    final fromRanges = (json['fromRanges'] as List)
        .map((r) => toDomainRange(r as Map<String, dynamic>))
        .toList();

    return CallHierarchyIncomingCall(
      from: _toDomainCallHierarchyItemSingle(json['from'] as Map<String, dynamic>),
      fromRanges: fromRanges,
    );
  }

  /// Converts list of LSP outgoing calls to domain.
  static List<CallHierarchyOutgoingCall> toDomainOutgoingCalls(List<dynamic>? json) {
    if (json == null) return [];

    return json
        .map((item) => _toDomainOutgoingCall(item as Map<String, dynamic>))
        .toList();
  }

  /// Converts single LSP outgoing call to domain.
  static CallHierarchyOutgoingCall _toDomainOutgoingCall(Map<String, dynamic> json) {
    final fromRanges = (json['fromRanges'] as List)
        .map((r) => toDomainRange(r as Map<String, dynamic>))
        .toList();

    return CallHierarchyOutgoingCall(
      to: _toDomainCallHierarchyItemSingle(json['to'] as Map<String, dynamic>),
      fromRanges: fromRanges,
    );
  }

  // ================================================================
  // Type Hierarchy Mapping
  // ================================================================

  /// Converts LSP type hierarchy item to domain (handles array or null).
  static TypeHierarchyItem? toDomainTypeHierarchyItem(List<dynamic>? json) {
    if (json == null || json.isEmpty) return null;
    return _toDomainTypeHierarchyItemSingle(json.first as Map<String, dynamic>);
  }

  /// Converts single LSP type hierarchy item to domain.
  static TypeHierarchyItem _toDomainTypeHierarchyItemSingle(Map<String, dynamic> json) {
    return TypeHierarchyItem(
      name: json['name'] as String,
      kind: _toSymbolKind(json['kind'] as int),
      detail: json['detail'] as String?,
      uri: DocumentUri(json['uri'] as String),
      range: toDomainRange(json['range'] as Map<String, dynamic>),
      selectionRange: toDomainRange(json['selectionRange'] as Map<String, dynamic>),
    );
  }

  /// Converts domain type hierarchy item to LSP format.
  static Map<String, dynamic> fromDomainTypeHierarchyItem(TypeHierarchyItem item) {
    return {
      'name': item.name,
      'kind': _fromSymbolKind(item.kind),
      if (item.detail != null) 'detail': item.detail,
      'uri': item.uri.value,
      'range': fromDomainRange(item.range),
      'selectionRange': fromDomainRange(item.selectionRange),
    };
  }

  /// Converts list of LSP type hierarchy items to domain.
  static List<TypeHierarchyItem> toDomainTypeHierarchyItems(List<dynamic>? json) {
    if (json == null) return [];

    return json
        .map((item) => _toDomainTypeHierarchyItemSingle(item as Map<String, dynamic>))
        .toList();
  }

  // ================================================================
  // Code Lens Mapping
  // ================================================================

  /// Converts list of LSP code lenses to domain.
  static List<CodeLens> toDomainCodeLenses(List<dynamic>? json) {
    if (json == null) return [];

    return json
        .map((item) => toDomainCodeLens(item as Map<String, dynamic>))
        .toList();
  }

  /// Converts single LSP code lens to domain.
  static CodeLens toDomainCodeLens(Map<String, dynamic> json) {
    Command? command;
    if (json.containsKey('command') && json['command'] != null) {
      final commandJson = json['command'] as Map<String, dynamic>;
      command = Command(
        title: commandJson['title'] as String,
        command: commandJson['command'] as String,
        arguments: commandJson['arguments'] as List<dynamic>?,
      );
    }

    return CodeLens(
      range: toDomainRange(json['range'] as Map<String, dynamic>),
      command: command,
      data: json['data'],
    );
  }

  /// Converts domain code lens to LSP format.
  static Map<String, dynamic> fromDomainCodeLens(CodeLens codeLens) {
    final result = <String, dynamic>{
      'range': fromDomainRange(codeLens.range),
    };

    if (codeLens.command != null) {
      result['command'] = {
        'title': codeLens.command!.title,
        'command': codeLens.command!.command,
        if (codeLens.command!.arguments != null)
          'arguments': codeLens.command!.arguments,
      };
    }

    if (codeLens.data != null) {
      result['data'] = codeLens.data;
    }

    return result;
  }

  // ================================================================
  // Semantic Tokens Mapping
  // ================================================================

  /// Converts LSP semantic tokens to domain.
  static SemanticTokens toDomainSemanticTokens(Map<String, dynamic> json) {
    return SemanticTokens(
      resultId: json['resultId'] as String?,
      data: (json['data'] as List<dynamic>).cast<int>(),
    );
  }

  /// Converts LSP semantic tokens delta to domain.
  static SemanticTokensDelta toDomainSemanticTokensDelta(Map<String, dynamic> json) {
    final edits = (json['edits'] as List<dynamic>?)?.map((e) {
      final edit = e as Map<String, dynamic>;
      return SemanticTokensEdit(
        start: edit['start'] as int,
        deleteCount: edit['deleteCount'] as int,
        data: (edit['data'] as List<dynamic>?)?.cast<int>(),
      );
    }).toList() ?? [];

    return SemanticTokensDelta(
      resultId: json['resultId'] as String?,
      edits: edits,
    );
  }

  // ================================================================
  // Inlay Hint Mapping
  // ================================================================

  /// Converts list of LSP inlay hints to domain.
  static List<InlayHint> toDomainInlayHints(List<dynamic>? json) {
    if (json == null) return [];
    return json.map((item) => toDomainInlayHint(item as Map<String, dynamic>)).toList();
  }

  /// Converts single LSP inlay hint to domain.
  static InlayHint toDomainInlayHint(Map<String, dynamic> json) {
    final position = toDomainPosition(json['position'] as Map<String, dynamic>);

    // Parse label (can be string or array of parts)
    final labelJson = json['label'];
    InlayHintLabel label;
    if (labelJson is String) {
      label = InlayHintLabel.string(labelJson);
    } else if (labelJson is List) {
      final parts = labelJson.map((p) {
        final part = p as Map<String, dynamic>;
        return InlayHintLabelPart(
          value: part['value'] as String,
          tooltip: part['tooltip'] as String?,
          location: part['location'] != null
              ? toDomainLocation(part['location'] as Map<String, dynamic>)
              : null,
        );
      }).toList();
      label = InlayHintLabel.parts(parts);
    } else {
      label = const InlayHintLabel.string('');
    }

    return InlayHint(
      position: position,
      label: label,
      kind: _toInlayHintKind(json['kind'] as int?),
      tooltip: json['tooltip'] as String?,
      paddingLeft: json['paddingLeft'] as bool? ?? false,
      paddingRight: json['paddingRight'] as bool? ?? false,
      data: json['data'],
    );
  }

  static InlayHintKind? _toInlayHintKind(int? kind) {
    if (kind == null) return null;
    switch (kind) {
      case 1:
        return InlayHintKind.type;
      case 2:
        return InlayHintKind.parameter;
      default:
        return InlayHintKind.other;
    }
  }

  /// Converts domain inlay hint to LSP format.
  static Map<String, dynamic> fromDomainInlayHint(InlayHint hint) {
    final result = <String, dynamic>{
      'position': fromDomainPosition(hint.position),
    };

    // Convert label
    hint.label.when(
      string: (value) => result['label'] = value,
      parts: (parts) => result['label'] = parts.map((p) {
        final partJson = <String, dynamic>{'value': p.value};
        if (p.tooltip != null) partJson['tooltip'] = p.tooltip;
        if (p.location != null) partJson['location'] = fromDomainLocation(p.location!);
        return partJson;
      }).toList(),
    );

    if (hint.kind != null) {
      result['kind'] = _fromInlayHintKind(hint.kind!);
    }
    if (hint.tooltip != null) result['tooltip'] = hint.tooltip;
    if (hint.paddingLeft) result['paddingLeft'] = true;
    if (hint.paddingRight) result['paddingRight'] = true;
    if (hint.data != null) result['data'] = hint.data;

    return result;
  }

  static int _fromInlayHintKind(InlayHintKind kind) {
    switch (kind) {
      case InlayHintKind.type:
        return 1;
      case InlayHintKind.parameter:
        return 2;
      case InlayHintKind.other:
        return 0;
    }
  }

  // ================================================================
  // Folding Range Mapping
  // ================================================================

  /// Converts list of LSP folding ranges to domain.
  static List<FoldingRange> toDomainFoldingRanges(List<dynamic>? json) {
    if (json == null) return [];
    return json.map((item) => _toDomainFoldingRange(item as Map<String, dynamic>)).toList();
  }

  static FoldingRange _toDomainFoldingRange(Map<String, dynamic> json) {
    return FoldingRange(
      startLine: json['startLine'] as int,
      startCharacter: json['startCharacter'] as int?,
      endLine: json['endLine'] as int,
      endCharacter: json['endCharacter'] as int?,
      kind: _toFoldingRangeKind(json['kind'] as String?),
      collapsedText: json['collapsedText'] as String?,
    );
  }

  static FoldingRangeKind? _toFoldingRangeKind(String? kind) {
    if (kind == null) return null;
    switch (kind) {
      case 'comment':
        return FoldingRangeKind.comment;
      case 'imports':
        return FoldingRangeKind.imports;
      case 'region':
        return FoldingRangeKind.region;
      default:
        return FoldingRangeKind.other;
    }
  }

  // ================================================================
  // Document Link Mapping
  // ================================================================

  /// Converts list of LSP document links to domain.
  static List<DocumentLink> toDomainDocumentLinks(List<dynamic>? json) {
    if (json == null) return [];
    return json.map((item) => toDomainDocumentLink(item as Map<String, dynamic>)).toList();
  }

  /// Converts single LSP document link to domain.
  static DocumentLink toDomainDocumentLink(Map<String, dynamic> json) {
    return DocumentLink(
      range: toDomainRange(json['range'] as Map<String, dynamic>),
      target: json['target'] as String?,
      tooltip: json['tooltip'] as String?,
      data: json['data'],
    );
  }

  /// Converts domain document link to LSP format.
  static Map<String, dynamic> fromDomainDocumentLink(DocumentLink link) {
    final result = <String, dynamic>{
      'range': fromDomainRange(link.range),
    };

    if (link.target != null) result['target'] = link.target;
    if (link.tooltip != null) result['tooltip'] = link.tooltip;
    if (link.data != null) result['data'] = link.data;

    return result;
  }
}
