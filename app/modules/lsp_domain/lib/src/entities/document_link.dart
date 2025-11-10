import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:editor_core/editor_core.dart';

part 'document_link.freezed.dart';

/// Document link represents a clickable link in the editor.
///
/// Examples:
/// - URLs: `https://example.com`
/// - File paths: `./config.json`
/// - Import paths: `package:foo/bar.dart`
@freezed
class DocumentLink with _$DocumentLink {
  const factory DocumentLink({
    /// Range of the link in the document
    required TextSelection range,

    /// Target URI (may be resolved later)
    String? target,

    /// Tooltip on hover
    String? tooltip,

    /// Data for resolve
    dynamic data,
  }) = _DocumentLink;
}
