import '../failures/domain_failure.dart';

class FileName {
  final String value;

  static const int maxLength = 255;
  static final RegExp _validPattern = RegExp(r'^[a-zA-Z0-9._-]+$');
  static final Set<String> _reservedNames = {
    'CON', 'PRN', 'AUX', 'NUL',
    'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
    'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9',
  };

  FileName._(this.value);

  static Either<DomainFailure, FileName> create(String input) {
    final trimmed = input.trim();

    if (trimmed.isEmpty) {
      return Left(
        DomainFailure.validationError(
          field: 'fileName',
          reason: 'File name cannot be empty',
          value: input,
        ),
      );
    }

    if (trimmed.length > maxLength) {
      return Left(
        DomainFailure.validationError(
          field: 'fileName',
          reason: 'File name cannot exceed $maxLength characters',
          value: input,
        ),
      );
    }

    if (!_validPattern.hasMatch(trimmed)) {
      return Left(
        DomainFailure.validationError(
          field: 'fileName',
          reason: 'File name contains invalid characters. Only letters, numbers, dots, hyphens, and underscores are allowed',
          value: input,
        ),
      );
    }

    final nameWithoutExt = trimmed.contains('.')
        ? trimmed.substring(0, trimmed.lastIndexOf('.'))
        : trimmed;

    if (_reservedNames.contains(nameWithoutExt.toUpperCase())) {
      return Left(
        DomainFailure.validationError(
          field: 'fileName',
          reason: 'File name is reserved by the system',
          value: input,
        ),
      );
    }

    if (trimmed.startsWith('.') && trimmed.length == 1) {
      return Left(
        DomainFailure.validationError(
          field: 'fileName',
          reason: 'File name cannot be just a dot',
          value: input,
        ),
      );
    }

    return Right(FileName._(trimmed));
  }

  String get extension {
    final parts = value.split('.');
    return parts.length > 1 ? parts.last : '';
  }

  String get nameWithoutExtension {
    if (!value.contains('.')) return value;
    return value.substring(0, value.lastIndexOf('.'));
  }

  bool get hasExtension => value.contains('.');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileName &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

class Either<L, R> {
  final L? _left;
  final R? _right;

  const Either._(this._left, this._right);

  bool get isLeft => _left != null;
  bool get isRight => _right != null;

  L get left {
    if (_left == null) {
      throw StateError('Cannot get left value from Right');
    }
    return _left as L;
  }

  R get right {
    if (_right == null) {
      throw StateError('Cannot get right value from Left');
    }
    return _right as R;
  }

  T fold<T>(T Function(L left) leftFn, T Function(R right) rightFn) {
    if (_left != null) return leftFn(_left as L);
    return rightFn(_right as R);
  }
}

class Left<L, R> extends Either<L, R> {
  const Left(L value) : super._(value, null);
}

class Right<L, R> extends Either<L, R> {
  const Right(R value) : super._(null, value);
}
