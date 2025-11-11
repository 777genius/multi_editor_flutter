/// Example: Using file_icons_wasm plugin
///
/// This example demonstrates how to load and use the Rust WASM plugin
/// from Dart code.
///
/// Run from project root:
/// ```bash
/// # 1. Build WASM plugin first
/// cd examples/plugins/file_icons_wasm
/// ./build.sh
/// cd ../../..
///
/// # 2. Run example
/// dart run examples/plugins/file_icons_wasm/example.dart
/// ```

import 'dart:io';
import 'package:flutter_plugin_system_core/flutter_plugin_system_core.dart';
import 'package:flutter_plugin_system_host/flutter_plugin_system_host.dart';
import 'package:flutter_plugin_system_wasm/flutter_plugin_system_wasm.dart';
import 'package:flutter_plugin_system_wasm_run/flutter_plugin_system_wasm_run.dart';

void main() async {
  print('🚀 File Icons WASM Plugin Example\n');

  // =========================================================================
  // 1. Setup Runtime and Manager
  // =========================================================================

  print('1️⃣  Setting up plugin system...');

  // Create WASM runtime
  final wasmRuntime = WasmRunRuntime(
    config: WasmRuntimeConfig(
      enableOptimization: true,
      maxMemoryPages: 16, // 1MB max
      maxStackDepth: 100,
      fuelLimit: 100000,
      enableWasi: false,
    ),
  );

  // Create plugin runtime
  final pluginRuntime = WasmPluginRuntime(
    wasmRuntime: wasmRuntime,
    serializer: MessagePackPluginSerializer(), // Use MessagePack
  );

  // Create error tracker
  final errorTracker = ErrorTracker();

  // Create plugin manager
  final pluginManager = PluginManager(
    registry: PluginRegistry(),
    hostFunctions: HostFunctionRegistry(),
    eventDispatcher: EventDispatcher(),
    permissionSystem: PermissionSystem(),
    securityGuard: SecurityGuard(PermissionSystem()),
    errorBoundary: ErrorBoundary(errorTracker),
  );

  print('   ✅ Plugin system initialized\n');

  // =========================================================================
  // 2. Register Host Functions
  // =========================================================================

  print('2️⃣  Registering host functions...');

  pluginManager.registerHostFunction('log_info', LogInfoFunction());

  print('   ✅ Host functions registered\n');

  // =========================================================================
  // 3. Load WASM Plugin
  // =========================================================================

  print('3️⃣  Loading WASM plugin...');

  final wasmPath = 'examples/plugins/file_icons_wasm/build/file_icons_wasm.wasm';

  if (!File(wasmPath).existsSync()) {
    print('   ❌ WASM file not found: $wasmPath');
    print('   💡 Run ./build.sh first!');
    exit(1);
  }

  try {
    final plugin = await pluginManager.loadPlugin(
      pluginId: 'plugin.file-icons-wasm',
      source: PluginSource.file(path: wasmPath),
      runtime: pluginRuntime,
    );

    final size = File(wasmPath).lengthSync();
    print('   ✅ Plugin loaded (${(size / 1024).toStringAsFixed(1)}KB)\n');

    // =======================================================================
    // 4. Test Plugin Functionality
    // =======================================================================

    print('4️⃣  Testing plugin functionality...\n');

    final testExtensions = [
      'rs',
      'dart',
      'js',
      'py',
      'html',
      'json',
      'unknown',
    ];

    for (final ext in testExtensions) {
      final response = await plugin.handleEvent(
        PluginEvent(
          type: 'get_icon',
          data: {'extension': ext},
          timestamp: DateTime.now(),
        ),
      );

      if (response.handled) {
        final icon = response.data['icon'];
        print('   .$ext → $icon');
      } else {
        print('   .$ext → ❌ Not handled');
      }
    }

    print('\n   ✅ All tests passed!\n');

    // =======================================================================
    // 5. Benchmark Performance
    // =======================================================================

    print('5️⃣  Benchmarking performance...\n');

    final iterations = 1000;
    final stopwatch = Stopwatch()..start();

    for (var i = 0; i < iterations; i++) {
      await plugin.handleEvent(
        PluginEvent(
          type: 'get_icon',
          data: {'extension': 'rs'},
          timestamp: DateTime.now(),
        ),
      );
    }

    stopwatch.stop();
    final avgMs = stopwatch.elapsedMicroseconds / iterations / 1000;

    print('   📊 $iterations iterations: ${stopwatch.elapsedMilliseconds}ms');
    print('   ⚡ Average: ${avgMs.toStringAsFixed(3)}ms per call\n');

    // =======================================================================
    // 6. Cleanup
    // =======================================================================

    print('6️⃣  Cleaning up...');

    await pluginManager.unloadPlugin('plugin.file-icons-wasm');
    await pluginManager.dispose();

    print('   ✅ Cleanup complete\n');

    print('✅ Example completed successfully!');
  } catch (e, st) {
    print('   ❌ Error: $e');
    print('   Stack trace: $st');
    exit(1);
  }
}

/// Example host function: log_info
///
/// Plugins can call this to log information to host.
class LogInfoFunction extends HostFunction<void> {
  @override
  HostFunctionSignature get signature => HostFunctionSignature(
        name: 'log_info',
        description: 'Log information message',
        returnType: 'void',
        params: [
          HostFunctionParam(
            'message',
            'String',
            'Message to log',
          ),
        ],
      );

  @override
  Future<void> call(List args) async {
    final message = args[0] as String;
    print('   [Plugin Log] $message');
  }
}
