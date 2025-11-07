import 'dart:async';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';

/// Mock PluginContext for testing
class MockPluginContext implements PluginContext {
  final Map<String, Map<String, dynamic>> _configurations = {};
  final Map<Type, Object> _services = {};
  final MockEventBus _eventBus = MockEventBus();

  @override
  CommandBus get commands => throw UnimplementedError();

  @override
  HookRegistry get hooks => throw UnimplementedError();

  @override
  FileRepository get fileRepository => throw UnimplementedError();

  @override
  FolderRepository get folderRepository => throw UnimplementedError();

  @override
  ProjectRepository get projectRepository => throw UnimplementedError();

  @override
  ValidationService get validationService => throw UnimplementedError();

  @override
  LanguageDetector get languageDetector => throw UnimplementedError();

  @override
  EventBus get events => _eventBus;

  @override
  Map<String, dynamic> getConfiguration(String pluginId) {
    return _configurations[pluginId] ?? {};
  }

  @override
  void setConfiguration(String pluginId, Map<String, dynamic> config) {
    _configurations[pluginId] = Map<String, dynamic>.from(config);
  }

  @override
  T? getService<T extends Object>() {
    return _services[T] as T?;
  }

  @override
  void registerService<T extends Object>(T service) {
    _services[T] = service;
  }

  // Test helpers
  Map<String, Map<String, dynamic>> get configurations => _configurations;
  MockEventBus get eventBus => _eventBus;
}

/// Mock EventBus for testing
class MockEventBus implements EventBus {
  final List<EditorEvent> _publishedEvents = [];
  final StreamController<EditorEvent> _controller =
      StreamController<EditorEvent>.broadcast();
  bool _isDisposed = false;

  List<EditorEvent> get publishedEvents => List.unmodifiable(_publishedEvents);

  @override
  void publish(EditorEvent event) {
    if (_isDisposed) return;
    _publishedEvents.add(event);
    _controller.add(event);
  }

  @override
  Stream<EditorEvent> get stream => _controller.stream;

  @override
  Stream<T> on<T extends EditorEvent>() {
    return stream.where((event) => event is T).cast<T>();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.close();
    _publishedEvents.clear();
  }

  // Test helpers
  void clear() {
    _publishedEvents.clear();
  }

  bool hasEventOfType<T extends EditorEvent>() {
    return _publishedEvents.any((event) => event is T);
  }

  T? getLastEventOfType<T extends EditorEvent>() {
    return _publishedEvents.whereType<T>().lastOrNull;
  }

  List<T> getEventsOfType<T extends EditorEvent>() {
    return _publishedEvents.whereType<T>().toList();
  }
}

/// Extension for list lastOrNull
extension _ListExtension<T> on Iterable<T> {
  T? get lastOrNull {
    if (isEmpty) return null;
    return last;
  }
}
