import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';

/// Widget that renders a file icon based on FileIconDescriptor.
///
/// This widget is part of the presentation layer and translates
/// the framework-agnostic FileIconDescriptor into actual Flutter widgets.
///
/// Supports:
/// - URL icons (lazy loaded from CDN)
/// - Local asset icons
/// - Icon font icons (MaterialIcons, custom fonts)
/// - Default icons (fallback)
class FileIconWidget extends StatelessWidget {
  final FileIconDescriptor descriptor;
  final Widget? fallback;

  const FileIconWidget({
    super.key,
    required this.descriptor,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (descriptor.type) {
      FileIconType.url => _buildUrlIcon(context),
      FileIconType.local => _buildAssetIcon(),
      FileIconType.iconData => _buildIconDataIcon(),
      FileIconType.defaultIcon => fallback ?? _buildDefaultIcon(),
    };

    // Add subtle glow effect for dark theme
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    if (isDarkTheme) {
      return Container(
        width: descriptor.size,
        height: descriptor.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.15),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: icon,
      );
    }

    return icon;
  }

  /// Build icon from remote URL with lazy loading
  /// Supports both SVG and raster formats (PNG, JPG)
  Widget _buildUrlIcon(BuildContext context) {
    final url = descriptor.url;

    if (url == null) {
      return _buildDefaultIcon();
    }

    // Check if URL is for SVG file (Devicon uses .svg extension)
    final isSvg = url.endsWith('.svg') || url.contains('devicon');

    if (isSvg) {
      // Devicon -original variant has colorful brand icons
      // No need for colorFilter - icons are already properly colored
      return SvgPicture.network(
        url,
        width: descriptor.size,
        height: descriptor.size,
        placeholderBuilder: (context) => SizedBox(
          width: descriptor.size,
          height: descriptor.size,
          child: Center(
            child: SizedBox(
              width: descriptor.size * 0.6,
              height: descriptor.size * 0.6,
              child: const CircularProgressIndicator(strokeWidth: 1.5),
            ),
          ),
        ),
        fit: BoxFit.contain,
      );
    }

    // Fallback to Image.network for raster formats (PNG, JPG)
    return Image.network(
      url,
      width: descriptor.size,
      height: descriptor.size,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to default icon on error
        return fallback ?? _buildDefaultIcon();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // Image loaded successfully
          return child;
        }
        // Show loading indicator
        return SizedBox(
          width: descriptor.size,
          height: descriptor.size,
          child: Center(
            child: SizedBox(
              width: descriptor.size * 0.6,
              height: descriptor.size * 0.6,
              child: const CircularProgressIndicator(strokeWidth: 1.5),
            ),
          ),
        );
      },
    );
  }

  /// Build icon from local asset
  Widget _buildAssetIcon() {
    final assetPath = descriptor.assetPath;
    if (assetPath == null) return _buildDefaultIcon();

    return Image.asset(
      assetPath,
      width: descriptor.size,
      height: descriptor.size,
      errorBuilder: (context, error, stackTrace) {
        return fallback ?? _buildDefaultIcon();
      },
    );
  }

  /// Build icon from IconData (icon font)
  Widget _buildIconDataIcon() {
    final iconCode = descriptor.iconCode;
    if (iconCode == null) return _buildDefaultIcon();

    return Icon(
      IconData(
        iconCode,
        fontFamily: descriptor.iconFamily,
      ),
      size: descriptor.size,
      color: descriptor.color != null ? Color(descriptor.color!) : null,
    );
  }

  /// Build default fallback icon
  Widget _buildDefaultIcon() {
    return Icon(
      Icons.insert_drive_file,
      size: descriptor.size,
    );
  }
}

/// Cached version of FileIconWidget with optimized image caching
class CachedFileIconWidget extends StatelessWidget {
  final FileIconDescriptor descriptor;
  final Widget? fallback;

  const CachedFileIconWidget({
    super.key,
    required this.descriptor,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    // For now, just use FileIconWidget
    // In the future, can add more sophisticated caching
    // with packages like cached_network_image
    return FileIconWidget(
      descriptor: descriptor,
      fallback: fallback,
    );
  }
}
