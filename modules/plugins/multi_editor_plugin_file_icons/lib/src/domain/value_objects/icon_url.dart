import 'package:freezed_annotation/freezed_annotation.dart';

part 'icon_url.freezed.dart';

/// Value Object representing a validated icon URL.
///
/// Ensures URL is valid and well-formed before use.
/// Immutable by design (DDD principle).
@freezed
sealed class IconUrl with _$IconUrl {
  const IconUrl._();

  const factory IconUrl({
    required String value,
  }) = _IconUrl;

  /// Factory constructor with validation
  factory IconUrl.parse(String url) {
    // Validate URL format
    if (url.isEmpty) {
      throw ArgumentError('URL cannot be empty');
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      throw ArgumentError('URL must start with http:// or https://');
    }

    // Check for common CDN patterns
    final isValidCdn = url.contains('jsdelivr.net') ||
        url.contains('unpkg.com') ||
        url.contains('cdnjs.cloudflare.com') ||
        url.contains('cdn.') ||
        url.contains('iconify.design') ||
        url.contains('raw.githubusercontent.com') ||
        Uri.tryParse(url) != null;

    if (!isValidCdn) {
      throw ArgumentError('Invalid icon URL format: $url');
    }

    return IconUrl(value: url);
  }

  /// Create from Iconify API
  /// Format: https://api.iconify.design/{collection}:{icon}.svg
  factory IconUrl.fromIconify({
    required String iconSet,
    required String iconName,
  }) {
    // Iconify API format uses colon, not slash
    final url = 'https://api.iconify.design/$iconSet:$iconName.svg';
    return IconUrl(value: url);
  }

  /// Create from jsDelivr CDN
  factory IconUrl.fromJsDelivr({
    required String package,
    required String version,
    required String path,
  }) {
    final url = 'https://cdn.jsdelivr.net/npm/$package@$version/$path';
    return IconUrl(value: url);
  }

  @override
  String toString() => value;
}
