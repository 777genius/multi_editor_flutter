/// Base Query class for CQRS pattern
/// Queries represent read operations (no state changes)
abstract class Query<TResult> {
  const Query();
}
