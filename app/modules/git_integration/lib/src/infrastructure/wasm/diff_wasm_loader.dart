import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

/// WASM diff loader for web platform
///
/// Loads and initializes the Rust WASM module for high-performance diff.
class DiffWasmLoader {
  static DiffWasmLoader? _instance;
  static bool _isInitialized = false;
  static bool _isLoading = false;
  static Completer<void>? _loadingCompleter;
  static html.ScriptElement? _wasmScript;

  DiffWasmLoader._();

  /// Get singleton instance
  static DiffWasmLoader get instance {
    _instance ??= DiffWasmLoader._();
    return _instance!;
  }

  /// Check if WASM is supported
  bool get isSupported {
    // WASM is only supported on web
    return kIsWeb;
  }

  /// Check if WASM is initialized
  bool get isInitialized => _isInitialized;

  /// Load and initialize WASM module
  Future<void> initialize() async {
    if (!isSupported) {
      throw UnsupportedError('WASM is only supported on web platform');
    }

    if (_isInitialized) {
      return;
    }

    // If already loading, wait for it to complete
    if (_isLoading) {
      return _loadingCompleter!.future;
    }

    _isLoading = true;
    _loadingCompleter = Completer<void>();

    try {
      // Load WASM module
      await _loadWasmModule();

      _isInitialized = true;
      _loadingCompleter!.complete();
    } catch (e) {
      _loadingCompleter!.completeError(e);
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Load WASM module from assets
  Future<void> _loadWasmModule() async {
    // CRITICAL: Clean up old script element if it exists (from previous failed attempt)
    // This prevents memory leak when retrying after failure
    if (_wasmScript != null) {
      _wasmScript!.remove();
      _wasmScript = null;
    }

    // Create script element to load WASM
    _wasmScript = html.ScriptElement()
      ..type = 'module'
      ..innerHtml = '''
        import init, { myers_diff, diff_stats } from './assets/wasm/git_diff_wasm.js';

        try {
          await init('./assets/wasm/git_diff_wasm_bg.wasm');

          // Expose functions to global scope
          window.gitDiffWasm = {
            myersDiff: myers_diff,
            diffStats: diff_stats,
            isLoaded: true,
          };

          console.log('✅ Git Diff WASM loaded successfully');
        } catch (error) {
          console.error('❌ Failed to load Git Diff WASM:', error);
          window.gitDiffWasm = { isLoaded: false, error: error.message };
        }
      ''';

    html.document.body?.append(_wasmScript!);

    // Wait for WASM to load (with timeout)
    final startTime = DateTime.now();
    const timeout = Duration(seconds: 10);

    while (DateTime.now().difference(startTime) < timeout) {
      final wasmObj = js.context['gitDiffWasm'];
      if (wasmObj != null) {
        final isLoaded = wasmObj['isLoaded'];
        if (isLoaded == true) {
          return;
        }
        if (isLoaded == false) {
          final error = wasmObj['error'];
          throw Exception('Failed to load WASM: $error');
        }
      }

      await Future.delayed(const Duration(milliseconds: 50));
    }

    throw TimeoutException('WASM loading timed out');
  }

  /// Compute diff using Myers algorithm
  ///
  /// Returns JSON string with diff hunks.
  String myersDiff({
    required String oldText,
    required String newText,
    int contextLines = 3,
  }) {
    if (!_isInitialized) {
      throw StateError('WASM not initialized. Call initialize() first.');
    }

    try {
      final wasmObj = js.context['gitDiffWasm'];
      final myersDiffFn = wasmObj['myersDiff'];

      final result = myersDiffFn.callMethod('call', [
        null, // this context
        oldText,
        newText,
        contextLines,
      ]);

      return result.toString();
    } catch (e) {
      throw Exception('Failed to compute diff: $e');
    }
  }

  /// Get diff statistics
  ///
  /// Returns JSON string with additions, deletions, and total changes.
  String diffStats({
    required String oldText,
    required String newText,
  }) {
    if (!_isInitialized) {
      throw StateError('WASM not initialized. Call initialize() first.');
    }

    try {
      final wasmObj = js.context['gitDiffWasm'];
      final diffStatsFn = wasmObj['diffStats'];

      final result = diffStatsFn.callMethod('call', [
        null, // this context
        oldText,
        newText,
      ]);

      return result.toString();
    } catch (e) {
      throw Exception('Failed to compute diff stats: $e');
    }
  }

  /// Parse diff result from JSON
  Map<String, dynamic> parseDiffResult(String json) {
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Failed to parse diff result: $e');
    }
  }

  /// Parse diff stats from JSON
  Map<String, int> parseDiffStats(String json) {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return {
        'additions': data['additions'] as int,
        'deletions': data['deletions'] as int,
        'total': data['total'] as int,
      };
    } catch (e) {
      throw FormatException('Failed to parse diff stats: $e');
    }
  }
}
