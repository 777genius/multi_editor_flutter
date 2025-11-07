import '../ui/plugin_ui_descriptor.dart';

/// Domain service for managing plugin UI registrations.
///
/// This is an abstract interface (domain layer) with NO implementation details.
/// Concrete implementations belong to the presentation layer.
///
/// ## Architecture:
/// - **Domain Layer** (here): defines WHAT operations are available
/// - **Presentation Layer**: implements HOW these operations work
///
/// ## SOLID Principles:
/// - **Dependency Inversion**: plugins depend on this abstraction, not concrete UI
/// - **Interface Segregation**: minimal interface for plugin UI management
///
/// ## Usage in plugins:
/// ```dart
/// @override
/// Future<void> onInitialize(PluginContext context) async {
///   final uiService = context.getService<PluginUIService>();
///   final descriptor = getUIDescriptor();
///   if (descriptor != null && uiService != null) {
///     uiService.registerUI(descriptor);
///   }
/// }
/// ```
abstract class PluginUIService {
  /// Register a plugin's UI descriptor
  ///
  /// This makes the plugin's UI available for display in the editor.
  /// If a descriptor with the same pluginId exists, it will be replaced.
  void registerUI(PluginUIDescriptor descriptor);

  /// Unregister a plugin's UI
  ///
  /// Removes the plugin's UI from the editor.
  /// Safe to call even if the plugin wasn't registered.
  void unregisterUI(String pluginId);

  /// Get all registered plugin UIs
  ///
  /// Returns a list sorted by priority (lower priority number = higher in list).
  List<PluginUIDescriptor> getRegisteredUIs();

  /// Get a specific plugin's UI descriptor
  ///
  /// Returns null if the plugin hasn't registered UI.
  PluginUIDescriptor? getUI(String pluginId);

  /// Stream of UI updates
  ///
  /// Emits when:
  /// - A new UI is registered
  /// - An existing UI is updated
  /// - A UI is unregistered
  ///
  /// This allows the presentation layer to reactively update the UI.
  Stream<PluginUIUpdateEvent> get updates;

  /// Check if a plugin has registered UI
  bool hasUI(String pluginId);
}

/// Event emitted when plugin UI registrations change
class PluginUIUpdateEvent {
  final PluginUIUpdateType type;
  final PluginUIDescriptor descriptor;

  const PluginUIUpdateEvent({required this.type, required this.descriptor});
}

/// Type of plugin UI update
enum PluginUIUpdateType {
  /// A new UI was registered
  registered,

  /// An existing UI was updated
  updated,

  /// A UI was unregistered
  unregistered,
}
