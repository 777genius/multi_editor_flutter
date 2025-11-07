import 'package:multi_editor_core/multi_editor_core.dart';
import '../commands/command_bus.dart';
import '../hooks/hook_registry.dart';

abstract class PluginContext {
  CommandBus get commands;

  EventBus get events;

  HookRegistry get hooks;

  FileRepository get fileRepository;

  FolderRepository get folderRepository;

  ProjectRepository get projectRepository;

  ValidationService get validationService;

  LanguageDetector get languageDetector;

  Map<String, dynamic> getConfiguration(String key);

  void setConfiguration(String key, Map<String, dynamic> value);

  T? getService<T extends Object>();

  void registerService<T extends Object>(T service);
}
