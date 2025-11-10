import 'dart:math' show Random;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:meta/meta.dart';

part 'session_id.freezed.dart';

/// Unique identifier for an LSP session.
@freezed
class SessionId with _$SessionId {
  const factory SessionId(String value) = _SessionId;

  const SessionId._();

  static final _random = Random();

  /// Generates a new unique session ID
  factory SessionId.generate() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random1 = _random.nextInt(0xFFFFFFFF);
    final random2 = _random.nextInt(0xFFFFFFFF);
    return SessionId('session_${timestamp}_${random1}_$random2');
  }

  /// Creates a session ID from a string
  factory SessionId.fromString(String value) {
    if (value.isEmpty) {
      throw ArgumentError('Session ID cannot be empty');
    }
    return SessionId(value);
  }
}
