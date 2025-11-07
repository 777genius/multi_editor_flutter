import 'plugin_manifest.dart';

/// Builder for constructing PluginManifest with a fluent API
///
/// Example usage:
/// ```dart
/// final manifest = PluginManifestBuilder()
///   .withId('my-plugin')
///   .withName('My Plugin')
///   .withVersion('1.0.0')
///   .withDescription('A sample plugin')
///   .withAuthor('John Doe')
///   .addDependency('plugin-a@^1.0.0')
///   .addDependency('plugin-b@^2.0.0')
///   .withCapability('lint', 'true')
///   .withCapability('format', 'true')
///   .addActivationEvent('onFileOpen:*.dart')
///   .withMetadata({'homepage': 'https://example.com'})
///   .build();
/// ```
class PluginManifestBuilder {
  String? _id;
  String? _name;
  String? _version;
  String? _description;
  String? _author;
  final List<String> _dependencies = [];
  final Map<String, String> _capabilities = {};
  final List<String> _activationEvents = [];
  final Map<String, dynamic> _metadata = {};

  PluginManifestBuilder();

  /// Set the plugin ID (required)
  PluginManifestBuilder withId(String id) {
    _id = id;
    return this;
  }

  /// Set the plugin name (required)
  PluginManifestBuilder withName(String name) {
    _name = name;
    return this;
  }

  /// Set the plugin version (required)
  PluginManifestBuilder withVersion(String version) {
    _version = version;
    return this;
  }

  /// Set the plugin description (optional)
  PluginManifestBuilder withDescription(String description) {
    _description = description;
    return this;
  }

  /// Set the plugin author (optional)
  PluginManifestBuilder withAuthor(String author) {
    _author = author;
    return this;
  }

  /// Add a single dependency
  PluginManifestBuilder addDependency(String dependency) {
    _dependencies.add(dependency);
    return this;
  }

  /// Add multiple dependencies
  PluginManifestBuilder withDependencies(List<String> dependencies) {
    _dependencies.addAll(dependencies);
    return this;
  }

  /// Add a single capability
  PluginManifestBuilder withCapability(String key, String value) {
    _capabilities[key] = value;
    return this;
  }

  /// Add multiple capabilities
  PluginManifestBuilder withCapabilities(Map<String, String> capabilities) {
    _capabilities.addAll(capabilities);
    return this;
  }

  /// Add a single activation event
  PluginManifestBuilder addActivationEvent(String event) {
    _activationEvents.add(event);
    return this;
  }

  /// Add multiple activation events
  PluginManifestBuilder withActivationEvents(List<String> events) {
    _activationEvents.addAll(events);
    return this;
  }

  /// Set metadata
  PluginManifestBuilder withMetadata(Map<String, dynamic> metadata) {
    _metadata.addAll(metadata);
    return this;
  }

  /// Add a single metadata entry
  PluginManifestBuilder addMetadata(String key, dynamic value) {
    _metadata[key] = value;
    return this;
  }

  /// Build the PluginManifest
  ///
  /// Throws [ArgumentError] if required fields are missing
  PluginManifest build() {
    // Validate required fields
    if (_id == null || _id!.isEmpty) {
      throw ArgumentError('Plugin ID is required');
    }
    if (_name == null || _name!.isEmpty) {
      throw ArgumentError('Plugin name is required');
    }
    if (_version == null || _version!.isEmpty) {
      throw ArgumentError('Plugin version is required');
    }

    // Validate version format (basic semver check)
    final versionRegex = RegExp(r'^\d+\.\d+\.\d+');
    if (!versionRegex.hasMatch(_version!)) {
      throw ArgumentError(
        'Invalid version format: $_version. Expected semver format (e.g., 1.0.0)',
      );
    }

    // Validate plugin ID format (lowercase, dots, hyphens only)
    final idRegex = RegExp(r'^[a-z0-9.-]+$');
    if (!idRegex.hasMatch(_id!)) {
      throw ArgumentError(
        'Invalid plugin ID: $_id. Must contain only lowercase letters, numbers, dots, and hyphens',
      );
    }

    return PluginManifest(
      id: _id!,
      name: _name!,
      version: _version!,
      description: _description,
      author: _author,
      dependencies: List.unmodifiable(_dependencies),
      capabilities: Map.unmodifiable(_capabilities),
      activationEvents: List.unmodifiable(_activationEvents),
      metadata: Map.unmodifiable(_metadata),
    );
  }

  /// Reset the builder to initial state
  void reset() {
    _id = null;
    _name = null;
    _version = null;
    _description = null;
    _author = null;
    _dependencies.clear();
    _capabilities.clear();
    _activationEvents.clear();
    _metadata.clear();
  }

  /// Create a builder from an existing manifest
  factory PluginManifestBuilder.fromManifest(PluginManifest manifest) {
    final builder = PluginManifestBuilder();
    builder
        .withId(manifest.id)
        .withName(manifest.name)
        .withVersion(manifest.version)
        .withDescription(manifest.description ?? '')
        .withAuthor(manifest.author ?? '');

    if (manifest.dependencies.isNotEmpty) {
      builder.withDependencies(manifest.dependencies);
    }
    if (manifest.capabilities.isNotEmpty) {
      builder.withCapabilities(manifest.capabilities);
    }
    if (manifest.activationEvents.isNotEmpty) {
      builder.withActivationEvents(manifest.activationEvents);
    }
    if (manifest.metadata.isNotEmpty) {
      builder.withMetadata(manifest.metadata);
    }

    return builder;
  }
}
