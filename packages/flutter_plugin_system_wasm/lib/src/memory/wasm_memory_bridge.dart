import 'dart:typed_data';
import '../contracts/i_wasm_instance.dart';
import '../contracts/i_wasm_memory.dart';
import '../serialization/plugin_serializer.dart';

/// WASM memory bridge
///
/// Manages memory allocation and data transfer between Dart (host) and WASM (plugin).
/// Implements the Linear Memory Pattern from architecture document (lines 620-773).
///
/// ## Memory Model
///
/// ```
/// Dart Memory                 WASM Linear Memory
///     │                             │
///     │ 1. Serialize data           │
///     ├──────────────────────────►  │
///     │                             │
///     │ 2. Allocate (call alloc)    │
///     ├──────────────────────────►  │
///     │                       [ptr] │
///     │                             │
///     │ 3. Write data to ptr        │
///     ├──────────────────────────►  │
///     │                    [data at ptr]
///     │                             │
///     │ 4. Call function(ptr, len)  │
///     ├──────────────────────────►  │
///     │                       [processing]
///     │                             │
///     │ 5. Return result_ptr        │
///     │◄──────────────────────────┤
///     │                             │
///     │ 6. Read result from ptr     │
///     │◄──────────────────────────┤
///     │                             │
///     │ 7. Free memory (dealloc)    │
///     ├──────────────────────────►  │
///     │                             │
/// ```
///
/// ## Example
///
/// ```dart
/// final bridge = WasmMemoryBridge(
///   instance: wasmInstance,
///   serializer: JsonPluginSerializer(),
/// );
///
/// // Call WASM function with automatic memory management
/// final result = await bridge.call(
///   'plugin_handle_event',
///   {'type': 'file.opened', 'filename': 'main.dart'},
/// );
///
/// print('Result: $result');
/// ```
class WasmMemoryBridge {
  final IWasmInstance _instance;
  final PluginSerializer _serializer;

  /// Get WASM instance
  IWasmInstance get instance => _instance;

  /// Get serializer
  PluginSerializer get serializer => _serializer;

  /// Create memory bridge
  ///
  /// ## Parameters
  ///
  /// - `instance`: WASM instance
  /// - `serializer`: Serializer for data conversion
  WasmMemoryBridge({
    required IWasmInstance instance,
    required PluginSerializer serializer,
  })  : _instance = instance,
        _serializer = serializer;

  /// Call WASM function with automatic memory management
  ///
  /// Handles the complete lifecycle:
  /// 1. Serialize input data
  /// 2. Allocate memory in WASM
  /// 3. Write data to WASM memory
  /// 4. Call WASM function
  /// 5. Read result from WASM memory
  /// 6. Deallocate memory
  /// 7. Deserialize result
  ///
  /// ## Parameters
  ///
  /// - `functionName`: WASM function to call
  /// - `data`: Input data (will be serialized)
  ///
  /// ## Returns
  ///
  /// Deserialized result data
  ///
  /// ## Throws
  ///
  /// - [WasmMemoryException] if memory operations fail
  /// - [SerializationException] if serialization fails
  /// - [ArgumentError] if required functions not found
  ///
  /// ## Example
  ///
  /// ```dart
  /// final event = {
  ///   'type': 'file.opened',
  ///   'data': {'filename': 'main.dart'},
  /// };
  ///
  /// final response = await bridge.call('plugin_handle_event', event);
  /// print('Response: $response');
  /// ```
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    final memory = _instance.memory;
    if (memory == null) {
      throw WasmMemoryException('WASM instance has no memory export');
    }

    final allocFn = _instance.getFunction('alloc');
    if (allocFn == null) {
      throw WasmMemoryException('WASM instance has no alloc function');
    }

    final deallocFn = _instance.getFunction('dealloc');
    if (deallocFn == null) {
      throw WasmMemoryException('WASM instance has no dealloc function');
    }

    final targetFn = _instance.getFunction(functionName);
    if (targetFn == null) {
      throw ArgumentError('Function not found: $functionName');
    }

    // 1. Serialize data
    final dataBytes = _serializer.serialize(data);
    final dataLen = dataBytes.length;

    // 2. Allocate memory for input
    final inputPtr = await allocFn([dataLen]) as int;

    try {
      // 3. Write data to WASM memory
      await memory.write(inputPtr, dataBytes);

      // 4. Call function (ptr, len) -> u64 (packed ptr + len)
      final packedResult = await targetFn([inputPtr, dataLen]) as int;

      // 5. Unpack result ptr + len
      final resultPtr = (packedResult >> 32) & 0xFFFFFFFF;
      final resultLen = packedResult & 0xFFFFFFFF;

      // Validate unpacked values
      // Check for null pointer (0,0) or invalid sentinel values
      if (packedResult == 0 || packedResult == 0xFFFFFFFFFFFFFFFF) {
        throw PluginCommunicationException(
          'Invalid packed result from WASM: packed=$packedResult (likely indicates plugin error)',
        );
      }

      // Sanity check: result should be reasonable size (max 100MB)
      if (resultLen > 100 * 1024 * 1024) {
        throw PluginCommunicationException(
          'Result too large: $resultLen bytes (max 100MB). ptr=$resultPtr, packed=$packedResult',
        );
      }

      // 6. Handle empty result
      if (resultLen == 0) {
        // Free result pointer even if length is 0 (WASM may have allocated)
        if (resultPtr != 0) {
          await deallocFn([resultPtr, resultLen]);
        }
        return {};
      }

      try {
        // 7. Read result from WASM memory
        final resultBytes = await memory.read(resultPtr, resultLen);

        // 8. Deserialize result
        return _serializer.deserialize(resultBytes);
      } finally {
        // 9. Free result memory (plugin allocated it)
        await deallocFn([resultPtr, resultLen]);
      }
    } finally {
      // 10. Free input memory (we allocated it)
      await deallocFn([inputPtr, dataLen]);
    }
  }

  /// Call WASM function without deserialization
  ///
  /// Returns raw bytes instead of deserializing.
  /// Useful when result needs custom processing.
  ///
  /// ## Parameters
  ///
  /// - `functionName`: WASM function to call
  /// - `data`: Input data (will be serialized)
  ///
  /// ## Returns
  ///
  /// Raw result bytes
  Future<Uint8List> callRaw(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    final memory = _instance.memory;
    if (memory == null) {
      throw WasmMemoryException('WASM instance has no memory export');
    }

    final allocFn = _instance.getFunction('alloc');
    if (allocFn == null) {
      throw WasmMemoryException('WASM instance has no alloc function');
    }

    final deallocFn = _instance.getFunction('dealloc');
    if (deallocFn == null) {
      throw WasmMemoryException('WASM instance has no dealloc function');
    }

    final targetFn = _instance.getFunction(functionName);
    if (targetFn == null) {
      throw ArgumentError('Function not found: $functionName');
    }

    final dataBytes = _serializer.serialize(data);
    final dataLen = dataBytes.length;

    final inputPtr = await allocFn([dataLen]) as int;

    try {
      await memory.write(inputPtr, dataBytes);

      final packedResult = await targetFn([inputPtr, dataLen]) as int;

      final resultPtr = (packedResult >> 32) & 0xFFFFFFFF;
      final resultLen = packedResult & 0xFFFFFFFF;

      // Validate unpacked values
      // Check for null pointer (0,0) or invalid sentinel values
      if (packedResult == 0 || packedResult == 0xFFFFFFFFFFFFFFFF) {
        throw WasmMemoryException(
          'Invalid packed result from WASM: packed=$packedResult (likely indicates plugin error)',
        );
      }

      // Sanity check: result should be reasonable size (max 100MB)
      if (resultLen > 100 * 1024 * 1024) {
        throw WasmMemoryException(
          'Result too large: $resultLen bytes (max 100MB). ptr=$resultPtr, packed=$packedResult',
        );
      }

      if (resultLen == 0) {
        // Free result pointer even if length is 0 (WASM may have allocated)
        if (resultPtr != 0) {
          await deallocFn([resultPtr, resultLen]);
        }
        return Uint8List(0);
      }

      try {
        return await memory.read(resultPtr, resultLen);
      } finally {
        await deallocFn([resultPtr, resultLen]);
      }
    } finally {
      await deallocFn([inputPtr, dataLen]);
    }
  }

  /// Allocate memory in WASM
  ///
  /// Allocates memory and returns pointer.
  /// Caller is responsible for freeing memory with [deallocate].
  ///
  /// ## Parameters
  ///
  /// - `size`: Number of bytes to allocate
  ///
  /// ## Returns
  ///
  /// Pointer to allocated memory
  ///
  /// ## Example
  ///
  /// ```dart
  /// final ptr = await bridge.allocate(1024);
  /// try {
  ///   // Use memory
  ///   await bridge.write(ptr, data);
  /// } finally {
  ///   await bridge.deallocate(ptr, 1024);
  /// }
  /// ```
  Future<int> allocate(int size) async {
    final allocFn = _instance.getFunction('alloc');
    if (allocFn == null) {
      throw WasmMemoryException('WASM instance has no alloc function');
    }

    return await allocFn([size]) as int;
  }

  /// Deallocate memory in WASM
  ///
  /// Frees previously allocated memory.
  ///
  /// ## Parameters
  ///
  /// - `ptr`: Pointer to memory
  /// - `size`: Size of allocation
  Future<void> deallocate(int ptr, int size) async {
    final deallocFn = _instance.getFunction('dealloc');
    if (deallocFn == null) {
      throw WasmMemoryException('WASM instance has no dealloc function');
    }

    await deallocFn([ptr, size]);
  }

  /// Write bytes to WASM memory
  ///
  /// Writes raw bytes to specified memory location.
  ///
  /// ## Parameters
  ///
  /// - `ptr`: Memory pointer
  /// - `data`: Bytes to write
  Future<void> write(int ptr, Uint8List data) async {
    final memory = _instance.memory;
    if (memory == null) {
      throw WasmMemoryException('WASM instance has no memory export');
    }

    await memory.write(ptr, data);
  }

  /// Read bytes from WASM memory
  ///
  /// Reads raw bytes from specified memory location.
  ///
  /// ## Parameters
  ///
  /// - `ptr`: Memory pointer
  /// - `length`: Number of bytes to read
  ///
  /// ## Returns
  ///
  /// Bytes read from memory
  Future<Uint8List> read(int ptr, int length) async {
    final memory = _instance.memory;
    if (memory == null) {
      throw WasmMemoryException('WASM instance has no memory export');
    }

    return await memory.read(ptr, length);
  }

  /// Get memory statistics
  ///
  /// Returns information about WASM memory usage.
  ///
  /// ## Returns
  ///
  /// Map with statistics:
  /// - `size_bytes`: Total memory size in bytes
  /// - `size_pages`: Total memory size in pages (64KB each)
  ///
  /// ## Example
  ///
  /// ```dart
  /// final stats = bridge.getMemoryStats();
  /// print('Memory: ${stats['size_bytes']} bytes (${stats['size_pages']} pages)');
  /// ```
  Map<String, dynamic> getMemoryStats() {
    final memory = _instance.memory;
    if (memory == null) {
      return {'size_bytes': 0, 'size_pages': 0};
    }

    return {
      'size_bytes': memory.size,
      'size_pages': memory.sizeInPages,
    };
  }
}

/// WASM memory exception
///
/// Thrown when WASM memory operations fail.
class WasmMemoryException implements Exception {
  final String message;
  final Object? originalError;

  const WasmMemoryException(this.message, {this.originalError});

  @override
  String toString() {
    if (originalError != null) {
      return 'WasmMemoryException: $message\nCaused by: $originalError';
    }
    return 'WasmMemoryException: $message';
  }
}
