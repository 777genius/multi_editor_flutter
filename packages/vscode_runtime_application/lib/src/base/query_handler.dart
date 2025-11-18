import 'package:dartz/dartz.dart';
import '../exceptions/application_exception.dart';
import 'query.dart';

/// Base Query Handler interface
/// Handles execution of queries
abstract class QueryHandler<TQuery extends Query<TResult>, TResult> {
  /// Execute the query
  /// Returns Either<ApplicationException, TResult>
  Future<Either<ApplicationException, TResult>> handle(TQuery query);
}
