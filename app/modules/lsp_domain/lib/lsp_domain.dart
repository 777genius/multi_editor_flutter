/// LSP domain layer - platform-agnostic LSP abstractions.
///
/// This package provides domain entities and interfaces for Language Server Protocol
/// operations without depending on any specific implementation.
library lsp_domain;

// Entities
export 'src/entities/completion_list.dart';
export 'src/entities/diagnostic.dart';
export 'src/entities/hover_info.dart';
export 'src/entities/lsp_session.dart';
export 'src/entities/code_action.dart';
export 'src/entities/signature_help.dart';
export 'src/entities/document_symbol.dart';
export 'src/entities/formatting_options.dart';
export 'src/entities/call_hierarchy.dart';
export 'src/entities/type_hierarchy.dart';
export 'src/entities/code_lens.dart';
export 'src/entities/semantic_tokens.dart';
export 'src/entities/inlay_hint.dart';
export 'src/entities/folding_range.dart';
export 'src/entities/document_link.dart';
export 'src/entities/location.dart';

// Value Objects
export 'src/value_objects/session_id.dart';

// Repositories (Ports)
export 'src/repositories/i_lsp_client_repository.dart';

// Failures
export 'src/failures/lsp_failure.dart';
