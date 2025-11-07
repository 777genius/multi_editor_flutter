import '../../domain/entities/file_icon.dart';
import '../../domain/repositories/icon_repository.dart';
import '../../domain/repositories/icon_theme_repository.dart';
import '../../domain/services/icon_resolution_service.dart';

/// Use case for getting an icon for a file.
///
/// Orchestrates domain services and repositories to fulfill business requirement.
class GetIconForFileUseCase {
  final IconRepository _iconRepository;
  final IconThemeRepository _themeRepository;
  final IconResolutionService _resolutionService;

  GetIconForFileUseCase(
    this._iconRepository,
    this._themeRepository,
    this._resolutionService,
  );

  /// Get icon for a filename.
  ///
  /// Returns null if no icon is available.
  Future<FileIcon?> execute(String filename) async {
    try {
      // 1. Extract extension from filename
      final extension = _resolutionService.extractExtension(filename);

      // 2. Check cache first
      final cachedIcon = await _iconRepository.getIcon(extension);
      if (cachedIcon != null && cachedIcon.isAvailable) {
        return cachedIcon;
      }

      // 3. Get active theme
      final theme = await _themeRepository.getActiveTheme();
      if (theme == null) return null;

      // 4. Resolve icon using domain service
      final icon = _resolutionService.createFileIcon(extension, theme);

      return icon;
    } catch (e) {
      // Log error and return null
      return null;
    }
  }
}
