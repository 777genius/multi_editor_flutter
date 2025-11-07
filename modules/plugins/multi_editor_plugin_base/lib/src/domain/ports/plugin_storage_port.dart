import 'package:multi_editor_core/multi_editor_core.dart';

typedef Either<L, R> = _Either<L, R>;
typedef Left<L, R> = _Left<L, R>;
typedef Right<L, R> = _Right<L, R>;

abstract class _Either<L, R> {
  const _Either();
  T fold<T>(T Function(L) leftFn, T Function(R) rightFn);
}

class _Left<L, R> extends _Either<L, R> {
  final L value;
  const _Left(this.value);

  @override
  T fold<T>(T Function(L) leftFn, T Function(R) rightFn) => leftFn(value);
}

class _Right<L, R> extends _Either<L, R> {
  final R value;
  const _Right(this.value);

  @override
  T fold<T>(T Function(L) leftFn, T Function(R) rightFn) => rightFn(value);
}

abstract class PluginStoragePort {
  Future<Either<DomainFailure, Map<String, dynamic>>> load(String key);

  Future<Either<DomainFailure, void>> save(String key, Map<String, dynamic> data);

  Future<Either<DomainFailure, void>> delete(String key);

  Future<Either<DomainFailure, bool>> exists(String key);

  Future<Either<DomainFailure, List<String>>> getAllKeys();

  Future<Either<DomainFailure, void>> clear();
}
