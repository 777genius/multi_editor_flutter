import '../../domain/entities/icon_theme.dart';
import '../../domain/repositories/icon_theme_repository.dart';

/// In-memory theme repository implementation.
class IconThemeRepositoryImpl implements IconThemeRepository {
  final Map<String, IconTheme> _themes = {};
  String? _activeThemeId;

  IconThemeRepositoryImpl() {
    // Register default Iconify theme
    _registerDefaultTheme();
  }

  void _registerDefaultTheme() {
    final defaultTheme = IconTheme(
      id: 'iconify-vscode',
      name: 'VSCode Icons (Iconify)',
      provider: 'iconify',
      baseUrl: 'https://api.iconify.design',
      priority: 50,
      isActive: true,
    );
    _themes[defaultTheme.id] = defaultTheme;
    _activeThemeId = defaultTheme.id;
  }

  @override
  Future<List<IconTheme>> getAvailableThemes() async {
    return _themes.values.toList();
  }

  @override
  Future<IconTheme?> getActiveTheme() async {
    if (_activeThemeId == null) return null;
    return _themes[_activeThemeId];
  }

  @override
  Future<void> setActiveTheme(String themeId) async {
    if (_themes.containsKey(themeId)) {
      // Deactivate all themes
      _themes.forEach((key, theme) {
        _themes[key] = theme.copyWith(isActive: false);
      });

      // Activate selected theme
      _themes[themeId] = _themes[themeId]!.copyWith(isActive: true);
      _activeThemeId = themeId;
    }
  }

  @override
  Future<IconTheme?> getTheme(String themeId) async {
    return _themes[themeId];
  }

  @override
  Future<void> registerTheme(IconTheme theme) async {
    _themes[theme.id] = theme;
  }

  @override
  Future<bool> hasTheme(String themeId) async {
    return _themes.containsKey(themeId);
  }
}
