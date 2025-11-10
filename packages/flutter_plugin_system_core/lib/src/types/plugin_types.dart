/// Plugin system type definitions
///
/// Defines core types and enums used throughout the plugin system.
library;

/// Plugin runtime type
///
/// Specifies which runtime will execute the plugin.
enum PluginRuntimeType {
  /// WebAssembly runtime (Rust, Go, C, JavaScript compiled to WASM)
  wasm('wasm'),

  /// Native Dart plugin (pure Dart implementation)
  native('native'),

  /// Script runtime (JavaScript, Lua, Python - future support)
  script('script');

  const PluginRuntimeType(this.value);

  final String value;

  /// Parse from string
  static PluginRuntimeType fromString(String value) {
    return PluginRuntimeType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Unknown runtime type: $value'),
    );
  }

  @override
  String toString() => value;
}

/// Plugin lifecycle state
///
/// Represents the current state of a plugin in its lifecycle.
enum PluginState {
  /// Plugin is not loaded
  unloaded('unloaded'),

  /// Plugin is being loaded
  loading('loading'),

  /// Plugin is loaded but not initialized
  loaded('loaded'),

  /// Plugin is being initialized
  initializing('initializing'),

  /// Plugin is ready for use
  ready('ready'),

  /// Plugin encountered an error
  error('error'),

  /// Plugin is disposed
  disposed('disposed');

  const PluginState(this.value);

  final String value;

  /// Parse from string
  static PluginState fromString(String value) {
    return PluginState.values.firstWhere(
      (state) => state.value == value,
      orElse: () => throw ArgumentError('Unknown plugin state: $value'),
    );
  }

  /// Check if plugin is usable
  bool get isUsable => this == PluginState.ready;

  /// Check if plugin is in terminal state
  bool get isTerminal =>
      this == PluginState.error || this == PluginState.disposed;

  @override
  String toString() => value;
}

/// Plugin source type
///
/// Specifies where the plugin code is loaded from.
enum PluginSourceType {
  /// Load from filesystem path
  file('file'),

  /// Load from URL (remote)
  url('url'),

  /// Load from memory (embedded)
  memory('memory'),

  /// Load from package
  package('package');

  const PluginSourceType(this.value);

  final String value;

  static PluginSourceType fromString(String value) {
    return PluginSourceType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Unknown source type: $value'),
    );
  }

  @override
  String toString() => value;
}
