import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:editor_core/editor_core.dart';

part 'location.freezed.dart';

/// Represents a location in a document.
///
/// Used for navigation and cross-references:
/// - Go to definition
/// - Find references
/// - Inlay hint locations
@freezed
class Location with _$Location {
  const factory Location({
    /// Document URI
    required DocumentUri uri,

    /// Range in the document
    required TextSelection range,
  }) = _Location;
}
