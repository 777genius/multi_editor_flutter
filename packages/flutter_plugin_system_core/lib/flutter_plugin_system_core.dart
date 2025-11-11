/// Universal plugin system abstractions for Flutter
///
/// This package provides runtime-agnostic contracts and models for building
/// extensible plugin systems following Clean Architecture, DDD, and SOLID principles.
///
/// ## Features
///
/// - **Pure Abstractions**: Zero dependencies (except meta and annotations)
/// - **Runtime Agnostic**: Works with WASM, Native Dart, or Script runtimes
/// - **Type Safe**: Strongly typed interfaces with freezed models
/// - **Well Documented**: Comprehensive documentation for all APIs
/// - **Clean Architecture**: Clear separation of concerns
///
/// ## Core Concepts
///
/// ### Contracts (Interfaces)
///
/// - [IPlugin]: Base plugin interface
/// - [IPluginRuntime]: Runtime abstraction
/// - [IPluginHost]: Host capabilities
/// - [HostFunction]: Host function base class
///
/// ### Models (Immutable Data)
///
/// - [PluginManifest]: Plugin metadata
/// - [PluginContext]: Plugin execution context
/// - [PluginEvent]: Event structure
/// - [PluginResponse]: Response structure
/// - [PluginConfig]: Configuration
/// - [PluginSource]: Plugin code source
///
/// ### Types
///
/// - [PluginRuntimeType]: WASM, Native, Script
/// - [PluginState]: Lifecycle states
/// - [PluginSourceType]: File, URL, Memory, Package
///
/// ### Exceptions
///
/// - [PluginException]: Base exception
/// - [PluginLoadException]: Load failures
/// - [PluginInitializationException]: Init failures
/// - [PluginExecutionException]: Execution failures
///
/// ## Example Usage
///
/// ### Define a Plugin
///
/// ```dart
/// import 'package:flutter_plugin_system_core/flutter_plugin_system_core.dart';
///
/// class MyPlugin implements IPlugin {
///   @override
///   PluginManifest get manifest => PluginManifest(
///     id: 'com.example.my-plugin',
///     name: 'My Plugin',
///     version: '1.0.0',
///     description: 'Example plugin',
///     runtime: PluginRuntimeType.native,
///   );
///
///   @override
///   Future<void> initialize(PluginContext context) async {
///     // Setup
///   }
///
///   @override
///   Future<PluginResponse> handleEvent(PluginEvent event) async {
///     return PluginResponse.success(data: {'result': 'ok'});
///   }
///
///   @override
///   Future<void> dispose() async {
///     // Cleanup
///   }
/// }
/// ```
///
/// ### Define a Runtime
///
/// ```dart
/// class MyRuntime implements IPluginRuntime {
///   @override
///   PluginRuntimeType get type => PluginRuntimeType.native;
///
///   @override
///   Future<IPlugin> loadPlugin({
///     required String pluginId,
///     required PluginSource source,
///     PluginConfig? config,
///   }) async {
///     // Load and return plugin
///   }
///
///   @override
///   Future<void> unloadPlugin(String pluginId) async {
///     // Unload plugin
///   }
///
///   @override
///   bool isCompatible(PluginManifest manifest) {
///     return manifest.runtime == type;
///   }
/// }
/// ```
///
/// ### Define a Host Function
///
/// ```dart
/// class GetFileFunction extends HostFunction<FileDocument> {
///   @override
///   HostFunctionSignature get signature => HostFunctionSignature(
///     name: 'get_file',
///     description: 'Get file by ID',
///     params: [
///       HostFunctionParam('fileId', 'String', 'File ID'),
///     ],
///     returnType: 'FileDocument',
///   );
///
///   @override
///   Future<FileDocument> call(List<dynamic> args) async {
///     final fileId = args[0] as String;
///     return await fileRepository.getFile(fileId);
///   }
/// }
/// ```
///
/// ## See Also
///
/// - [flutter_plugin_system_host]: Plugin host runtime
/// - [flutter_plugin_system_wasm]: WASM plugin adapter
/// - [flutter_plugin_system_native]: Native Dart plugin runtime
library flutter_plugin_system_core;

// ============================================================================
// Contracts (Interfaces)
// ============================================================================

export 'src/contracts/i_plugin.dart';
export 'src/contracts/i_plugin_runtime.dart';
export 'src/contracts/i_plugin_host.dart';
export 'src/contracts/i_host_function.dart';

// ============================================================================
// Models (Immutable Data)
// ============================================================================

export 'src/models/plugin_manifest.dart';
export 'src/models/plugin_context.dart';
export 'src/models/plugin_event.dart';
export 'src/models/plugin_response.dart';
export 'src/models/plugin_config.dart';
export 'src/models/plugin_source.dart';

// ============================================================================
// Types (Enums)
// ============================================================================

export 'src/types/plugin_types.dart';

// ============================================================================
// Exceptions
// ============================================================================

export 'src/exceptions/plugin_exception.dart';
