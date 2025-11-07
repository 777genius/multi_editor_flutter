import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:multi_editor_plugin_base/multi_editor_plugin_base.dart';

import '../../domain/repositories/icon_repository.dart';
import '../../domain/repositories/icon_theme_repository.dart';
import '../../domain/services/icon_resolution_service.dart';
import '../../infrastructure/providers/iconify_provider.dart';
import '../../infrastructure/repositories/icon_repository_impl.dart';
import '../../infrastructure/repositories/icon_theme_repository_impl.dart';
import '../../infrastructure/services/icon_cache_service.dart';
import '../config/file_icons_config.dart';

/// File Icons Plugin - provides beautiful icons for file tree.
///
/// Uses Devicon CDN (150+ colorful icons) for lazy-loaded SVG icons with LRU caching.
class FileIconsPlugin extends BaseEditorPlugin with StatefulPlugin {
  final FileIconsConfig config;

  // Dependencies (DI)
  late final IconCacheService _cacheService;
  late final IconRepository _iconRepository;
  late final IconThemeRepository _themeRepository;
  late final IconResolutionService _resolutionService;
  late final SimpleIconsProvider _simpleIconsProvider;

  FileIconsPlugin({
    FileIconsConfig? config,
  }) : config = config ?? const FileIconsConfig();

  @override
  PluginManifest get manifest => PluginManifest(
        id: 'plugin.file-icons',
        name: 'File Icons',
        version: '0.2.0',
        description:
            'Provides beautiful colorful icons for files using Devicon CDN (150+ icons) with lazy SVG loading',
        author: 'Editor Team',
      );

  @override
  Future<void> onInitialize(PluginContext context) async {
    // Initialize dependencies
    _cacheService = IconCacheService(maxSize: config.maxCacheSize);
    _iconRepository = IconRepositoryImpl(_cacheService);
    _themeRepository = IconThemeRepositoryImpl();
    _resolutionService = IconResolutionService();
    _simpleIconsProvider = SimpleIconsProvider();

    // Set active theme
    await _themeRepository.setActiveTheme(config.defaultTheme);
  }

  @override
  Future<void> onDispose() async {
    _simpleIconsProvider.dispose();
    await _iconRepository.clearCache();
  }

  @override
  FileIconDescriptor? getFileIconDescriptor(FileTreeNode node) {
    // Only provide icons for files, not folders
    if (node.type != FileTreeNodeType.file) {
      return null;
    }

    try {
      // Get icon URL from Simple Icons provider
      final extension = _resolutionService.extractExtension(node.name);
      final iconUrl = _simpleIconsProvider.getIconUrl(extension.value);

      return FileIconDescriptor.url(
        url: iconUrl.value,
        size: config.iconSize.toDouble(),
        priority: config.priority,
        pluginId: manifest.id,
      );
    } catch (e) {
      // Return null to use default icon on error
      return null;
    }
  }
}
