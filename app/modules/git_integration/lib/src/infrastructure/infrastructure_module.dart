import 'package:injectable/injectable.dart';
import 'adapters/git_command_adapter.dart';
import 'adapters/git_parser_adapter.dart';

/// Infrastructure module for dependency injection
///
/// Registers adapters and other infrastructure components.
@module
abstract class InfrastructureModule {
  /// Register GitCommandAdapter
  @lazySingleton
  GitCommandAdapter get gitCommandAdapter => GitCommandAdapter();

  /// Register GitParserAdapter
  @lazySingleton
  GitParserAdapter get gitParserAdapter => GitParserAdapter();
}
