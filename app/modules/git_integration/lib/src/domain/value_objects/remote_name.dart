import 'package:freezed_annotation/freezed_annotation.dart';

part 'remote_name.freezed.dart';

/// Remote name value object with validation
@freezed
class RemoteName with _$RemoteName {
  const RemoteName._();

  const factory RemoteName({
    required String value,
  }) = _RemoteName;

  /// Factory with validation
  factory RemoteName.create(String value) {
    if (value.trim().isEmpty) {
      throw RemoteNameValidationException('Remote name cannot be empty');
    }

    // Git remote name rules:
    // - Cannot contain spaces
    // - Cannot contain '/'
    // - Should be alphanumeric with hyphens/underscores
    if (value.contains(' ')) {
      throw RemoteNameValidationException(
        'Remote name cannot contain spaces',
      );
    }

    if (value.contains('/')) {
      throw RemoteNameValidationException(
        'Remote name cannot contain "/"',
      );
    }

    final validPattern = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!validPattern.hasMatch(value)) {
      throw RemoteNameValidationException(
        'Remote name can only contain letters, numbers, hyphens, and underscores',
      );
    }

    return RemoteName(value: value);
  }

  /// Domain logic: Is origin?
  bool get isOrigin => value == 'origin';

  /// Domain logic: Is upstream?
  bool get isUpstream => value == 'upstream';

  /// Domain logic: Get default remote (origin is default)
  static RemoteName get defaultRemote => RemoteName(value: 'origin');
}

/// Exception for remote name validation
class RemoteNameValidationException implements Exception {
  final String message;
  RemoteNameValidationException(this.message);

  @override
  String toString() => 'RemoteNameValidationException: $message';
}
