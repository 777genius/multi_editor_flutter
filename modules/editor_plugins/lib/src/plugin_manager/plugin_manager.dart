import 'package:editor_core/editor_core.dart';
import '../plugin_api/editor_plugin.dart';
import '../plugin_api/plugin_context.dart';
import '../plugin_api/plugin_manifest.dart';

class PluginManager {
  final PluginContext _context;
  final Map<String, EditorPlugin> _plugins = {};
  final Map<String, bool> _activatedPlugins = {};

  PluginManager(this._context);

  Future<void> registerPlugin(EditorPlugin plugin) async {
    final manifest = plugin.manifest;

    if (_plugins.containsKey(manifest.id)) {
      throw PluginException(
        'Plugin "${manifest.id}" is already registered',
      );
    }

    _validateDependencies(plugin);

    _plugins[manifest.id] = plugin;
    _activatedPlugins[manifest.id] = false;

    await _activatePlugin(plugin);
  }

  Future<void> _activatePlugin(EditorPlugin plugin) async {
    final manifest = plugin.manifest;

    if (_activatedPlugins[manifest.id] == true) {
      return;
    }

    for (final depId in manifest.dependencies) {
      if (!_plugins.containsKey(depId)) {
        throw PluginException(
          'Plugin "${manifest.id}" depends on "$depId" which is not registered',
        );
      }
      if (_activatedPlugins[depId] != true) {
        await _activatePlugin(_plugins[depId]!);
      }
    }

    await plugin.initialize(_context);
    _activatedPlugins[manifest.id] = true;

    _subscribeToEvents(plugin);
  }

  void _subscribeToEvents(EditorPlugin plugin) {
    _context.events.on<FileOpened>().listen((event) {
      plugin.onFileOpen(event.file);
    });

    _context.events.on<FileClosed>().listen((event) {
      plugin.onFileClose(event.fileId);
    });

    _context.events.on<FileSaved>().listen((event) {
      plugin.onFileSave(event.file);
    });

    _context.events.on<FileContentChanged>().listen((event) {
      plugin.onFileContentChange(event.fileId, event.content);
    });

    _context.events.on<FileCreated>().listen((event) {
      plugin.onFileCreate(event.file);
    });

    _context.events.on<FileDeleted>().listen((event) {
      plugin.onFileDelete(event.fileId);
    });

    _context.events.on<FolderCreated>().listen((event) {
      plugin.onFolderCreate(event.folder);
    });

    _context.events.on<FolderDeleted>().listen((event) {
      plugin.onFolderDelete(event.folderId);
    });
  }

  void _validateDependencies(EditorPlugin plugin) {
    final manifest = plugin.manifest;
    for (final depId in manifest.dependencies) {
      if (!_plugins.containsKey(depId)) {
        throw PluginException(
          'Plugin "${manifest.id}" has unmet dependency: "$depId"',
        );
      }
    }
  }

  Future<void> unregisterPlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) {
      return;
    }

    for (final otherPlugin in _plugins.values) {
      if (otherPlugin.manifest.dependencies.contains(pluginId)) {
        throw PluginException(
          'Cannot unregister plugin "$pluginId" because it is required by "${otherPlugin.manifest.id}"',
        );
      }
    }

    if (_activatedPlugins[pluginId] == true) {
      await plugin.dispose();
    }

    _plugins.remove(pluginId);
    _activatedPlugins.remove(pluginId);
  }

  EditorPlugin? getPlugin(String pluginId) => _plugins[pluginId];

  bool isPluginRegistered(String pluginId) => _plugins.containsKey(pluginId);

  bool isPluginActivated(String pluginId) =>
      _activatedPlugins[pluginId] ?? false;

  List<PluginManifest> get allPlugins =>
      _plugins.values.map((p) => p.manifest).toList();

  /// Get all registered plugins
  List<EditorPlugin> get plugins => _plugins.values.toList();

  List<EditorPlugin> getPluginsForLanguage(String language) {
    return _plugins.values
        .where((p) => p.supportsLanguage(language))
        .toList();
  }

  Future<void> disposeAll() async {
    for (final plugin in _plugins.values) {
      if (_activatedPlugins[plugin.manifest.id] == true) {
        await plugin.dispose();
      }
    }
    _plugins.clear();
    _activatedPlugins.clear();
  }
}

class PluginException implements Exception {
  final String message;

  PluginException(this.message);

  @override
  String toString() => 'PluginException: $message';
}
