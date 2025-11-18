/// Application Layer Exceptions
/// Exceptions thrown by use cases and handlers

abstract class ApplicationException implements Exception {
  final String message;
  final Exception? innerException;

  const ApplicationException(this.message, [this.innerException]);

  @override
  String toString() {
    final inner = innerException != null ? ' (${innerException})' : '';
    return 'ApplicationException: $message$inner';
  }
}

/// Exception when a resource is not found
class NotFoundException extends ApplicationException {
  const NotFoundException(super.message, [super.innerException]);
}

/// Exception when an operation is invalid in current state
class InvalidOperationException extends ApplicationException {
  const InvalidOperationException(super.message, [super.innerException]);
}

/// Exception when an operation is cancelled
class OperationCancelledException extends ApplicationException {
  const OperationCancelledException([String? message])
      : super(message ?? 'Operation was cancelled');
}

/// Exception when network operation fails
class NetworkException extends ApplicationException {
  const NetworkException(super.message, [super.innerException]);
}

/// Exception when file system operation fails
class FileSystemException extends ApplicationException {
  const FileSystemException(super.message, [super.innerException]);
}

/// Exception when validation fails
class ValidationException extends ApplicationException {
  final Map<String, String> errors;

  const ValidationException(super.message, [this.errors = const {}]);

  @override
  String toString() {
    if (errors.isEmpty) return super.toString();
    final errorDetails = errors.entries
        .map((e) => '  ${e.key}: ${e.value}')
        .join('\n');
    return 'ValidationException: $message\n$errorDetails';
  }
}
