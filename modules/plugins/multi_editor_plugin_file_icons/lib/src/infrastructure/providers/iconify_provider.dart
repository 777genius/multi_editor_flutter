import 'package:http/http.dart' as http;
import '../../domain/value_objects/icon_url.dart';

/// Provider for file icons via Devicon CDN.
///
/// Uses Devicon (150+ icons) for programming languages and development tools
/// with colorful SVG format using -original variant.
/// See: https://devicon.dev/
class SimpleIconsProvider {
  final http.Client _client;

  // Devicon CDN - 150+ colorful programming language icons
  static const String _deviconBaseUrl =
      'https://cdn.jsdelivr.net/gh/devicons/devicon/icons';

  SimpleIconsProvider([http.Client? client])
    : _client = client ?? http.Client();

  /// Get icon URL for a file extension.
  /// Uses Devicon CDN with colorful -original.svg variant.
  IconUrl getIconUrl(String extension) {
    final iconName = _getIconSlug(extension);

    // Build Devicon URL: icons/{name}/{name}-original.svg
    final url = '$_deviconBaseUrl/$iconName/$iconName-original.svg';
    return IconUrl.parse(url);
  }

  /// Map file extension to Devicon icon name
  /// Devicon uses lowercase names matching technology names
  String _getIconSlug(String extension) {
    // Map extensions to Devicon icon names
    // See: https://devicon.dev/ for available icons
    final iconMap = {
      // Programming Languages
      'dart': 'dart',
      'js': 'javascript',
      'mjs': 'javascript',
      'cjs': 'javascript',
      'ts': 'typescript',
      'tsx': 'typescript',
      'jsx': 'react',
      'py': 'python',
      'java': 'java',
      'go': 'go',
      'rs': 'rust',
      'cpp': 'cplusplus',
      'cc': 'cplusplus',
      'c': 'c',
      'cs': 'csharp',
      'php': 'php',
      'rb': 'ruby',
      'swift': 'swift',
      'kt': 'kotlin',
      'kts': 'kotlin',
      'r': 'r',
      'lua': 'lua',
      'pl': 'perl',
      'scala': 'scala',
      'groovy': 'groovy',
      'ex': 'elixir',
      'exs': 'elixir',
      'erl': 'erlang',
      'hs': 'haskell',
      'clj': 'clojure',
      'fs': 'fsharp',

      // Web Technologies
      'html': 'html5',
      'htm': 'html5',
      'css': 'css3',
      'scss': 'sass',
      'sass': 'sass',
      'less': 'less',
      'vue': 'vuejs',
      'svelte': 'svelte',

      // Data & Config
      'json': 'json',
      'xml': 'xml',
      'yaml': 'yaml',
      'yml': 'yaml',
      'toml': 'toml',

      // Markdown & Docs
      'md': 'markdown',

      // Shell & Scripts
      'sh': 'bash',
      'bash': 'bash',

      // Database
      'sql': 'mysql',
      'mysql': 'mysql',
      'postgres': 'postgresql',
      'postgresql': 'postgresql',
      'mongo': 'mongodb',
      'mongodb': 'mongodb',
      'redis': 'redis',

      // DevOps & Tools
      'docker': 'docker',
      'dockerfile': 'docker',
      'nginx': 'nginx',
      'git': 'git',
      'gitignore': 'git',

      // Build Tools
      'gradle': 'gradle',

      // Package Managers
      'lock': 'npm',

      // Images & Assets
      'svg': 'svg',
    };

    return iconMap[extension.toLowerCase()] ?? 'file';
  }

  /// Check if icon exists (by attempting to load it).
  Future<bool> iconExists(String extension) async {
    try {
      final url = getIconUrl(extension);
      final response = await _client.head(Uri.parse(url.value));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}
