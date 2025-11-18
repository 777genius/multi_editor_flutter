/// Base Command class for CQRS pattern
/// Commands represent write operations (state changes)
abstract class Command<TResult> {
  const Command();
}
