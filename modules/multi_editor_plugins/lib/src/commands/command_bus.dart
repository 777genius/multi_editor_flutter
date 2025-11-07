import 'dart:async';

typedef CommandHandler<TInput, TOutput> = Future<TOutput> Function(TInput input);

class Command<TInput, TOutput> {
  final String id;
  final CommandHandler<TInput, TOutput> handler;

  const Command({
    required this.id,
    required this.handler,
  });

  Future<TOutput> execute(TInput input) => handler(input);
}

class CommandBus {
  final Map<String, Command<dynamic, dynamic>> _commands = {};

  void register<TInput, TOutput>(Command<TInput, TOutput> command) {
    if (_commands.containsKey(command.id)) {
      throw StateError('Command "${command.id}" is already registered');
    }
    _commands[command.id] = command;
  }

  void unregister(String commandId) {
    _commands.remove(commandId);
  }

  Future<TOutput> execute<TInput, TOutput>(
    String commandId,
    TInput input,
  ) async {
    final command = _commands[commandId];
    if (command == null) {
      throw StateError('Command "$commandId" is not registered');
    }

    try {
      final result = await command.execute(input);
      return result as TOutput;
    } catch (e) {
      throw CommandExecutionException(
        commandId: commandId,
        cause: e,
      );
    }
  }

  bool hasCommand(String commandId) => _commands.containsKey(commandId);

  List<String> get allCommandIds => _commands.keys.toList();

  void clear() {
    _commands.clear();
  }
}

class CommandExecutionException implements Exception {
  final String commandId;
  final Object cause;

  CommandExecutionException({
    required this.commandId,
    required this.cause,
  });

  @override
  String toString() =>
      'CommandExecutionException: Failed to execute command "$commandId": $cause';
}
