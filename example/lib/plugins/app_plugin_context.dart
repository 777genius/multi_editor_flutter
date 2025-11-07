import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';

class AppPluginContext implements PluginContext {
  final FileRepository _fileRepository;
  final FolderRepository _folderRepository;
  final ProjectRepository _projectRepository;
  final ValidationService _validationService;
  final LanguageDetector _languageDetector;
  final EventBus _eventBus;
  final CommandBus _commandBus;
  final HookRegistry _hookRegistry;
  final Map<String, dynamic> _configuration = {};
  final Map<Type, Object> _services = {};

  AppPluginContext({
    required FileRepository fileRepository,
    required FolderRepository folderRepository,
    required ProjectRepository projectRepository,
    required ValidationService validationService,
    required LanguageDetector languageDetector,
    required EventBus eventBus,
    CommandBus? commandBus,
    HookRegistry? hookRegistry,
  }) : _fileRepository = fileRepository,
       _folderRepository = folderRepository,
       _projectRepository = projectRepository,
       _validationService = validationService,
       _languageDetector = languageDetector,
       _eventBus = eventBus,
       _commandBus = commandBus ?? CommandBus(),
       _hookRegistry = hookRegistry ?? HookRegistry();

  @override
  CommandBus get commands => _commandBus;

  @override
  EventBus get events => _eventBus;

  @override
  HookRegistry get hooks => _hookRegistry;

  @override
  FileRepository get fileRepository => _fileRepository;

  @override
  FolderRepository get folderRepository => _folderRepository;

  @override
  ProjectRepository get projectRepository => _projectRepository;

  @override
  ValidationService get validationService => _validationService;

  @override
  LanguageDetector get languageDetector => _languageDetector;

  @override
  Map<String, dynamic> getConfiguration(String key) {
    return _configuration[key] as Map<String, dynamic>? ?? {};
  }

  @override
  void setConfiguration(String key, Map<String, dynamic> value) {
    _configuration[key] = value;
  }

  @override
  T? getService<T extends Object>() {
    return _services[T] as T?;
  }

  @override
  void registerService<T extends Object>(T service) {
    _services[T] = service;
  }
}
