import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';

/// Mock implementation of PluginContext for testing
class MockPluginContext implements PluginContext {
  final Map<String, dynamic> _configuration = {};
  final Map<Type, Object> _services = {};

  @override
  CommandBus get commands => throw UnimplementedError('CommandBus mock not implemented');

  @override
  EventBus get events => MockEventBus();

  @override
  HookRegistry get hooks => throw UnimplementedError('HookRegistry mock not implemented');

  @override
  FileRepository get fileRepository => throw UnimplementedError('FileRepository mock not implemented');

  @override
  FolderRepository get folderRepository => throw UnimplementedError('FolderRepository mock not implemented');

  @override
  ProjectRepository get projectRepository => throw UnimplementedError('ProjectRepository mock not implemented');

  @override
  ValidationService get validationService => throw UnimplementedError('ValidationService mock not implemented');

  @override
  LanguageDetector get languageDetector => throw UnimplementedError('LanguageDetector mock not implemented');

  @override
  Map<String, dynamic> getConfiguration(String key) {
    return _configuration[key] ?? {};
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

/// Mock EventBus for testing
class MockEventBus implements EventBus {
  final List<EditorEvent> _events = [];
  bool _disposed = false;

  @override
  Stream<T> on<T extends EditorEvent>() {
    return Stream.empty();
  }

  @override
  void publish(EditorEvent event) {
    if (_disposed) return;
    _events.add(event);
  }

  @override
  Stream<EditorEvent> get stream => Stream.fromIterable(_events);

  @override
  void dispose() {
    _disposed = true;
    _events.clear();
  }

  List<EditorEvent> get firedEvents => List.unmodifiable(_events);

  void clear() {
    _events.clear();
  }
}
