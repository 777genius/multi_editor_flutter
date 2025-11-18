import 'package:dartz/dartz.dart';
import '../exceptions/application_exception.dart';
import 'command.dart';

/// Base Command Handler interface
/// Handles execution of commands
abstract class CommandHandler<TCommand extends Command<TResult>, TResult> {
  /// Execute the command
  /// Returns Either<ApplicationException, TResult>
  Future<Either<ApplicationException, TResult>> handle(TCommand command);
}
