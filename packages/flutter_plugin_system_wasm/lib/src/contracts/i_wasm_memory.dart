import 'dart:typed_data';

/// WASM linear memory interface
///
/// Represents the linear memory space of a WASM module.
/// Provides read/write operations for data exchange between host and WASM.
///
/// ## Memory Model
///
/// WASM uses a linear memory model:
/// - Memory is a contiguous array of bytes
/// - Addressable by byte offset
/// - Grows in 64KB pages
/// - Isolated from host memory
///
/// ## Example
///
/// ```dart
/// // Write data to WASM memory
/// final data = Uint8List.fromList([1, 2, 3, 4, 5]);
/// await memory.write(ptr, data);
///
/// // Read data from WASM memory
/// final result = await memory.read(resultPtr, resultLen);
/// ```
abstract class IWasmMemory {
  /// Get memory size in bytes
  ///
  /// Returns the current size of the linear memory.
  int get size;

  /// Get memory size in pages (64KB per page)
  ///
  /// Returns the current size in WASM pages.
  int get sizeInPages;

  /// Read bytes from memory
  ///
  /// Reads a byte array from the specified memory location.
  ///
  /// ## Parameters
  ///
  /// - `offset`: Memory offset (pointer)
  /// - `length`: Number of bytes to read
  ///
  /// ## Returns
  ///
  /// Byte array read from memory
  ///
  /// ## Throws
  ///
  /// - [RangeError] if offset + length exceeds memory size
  ///
  /// ## Example
  ///
  /// ```dart
  /// final data = await memory.read(ptr, 100); // Read 100 bytes at ptr
  /// ```
  Future<Uint8List> read(int offset, int length);

  /// Write bytes to memory
  ///
  /// Writes a byte array to the specified memory location.
  ///
  /// ## Parameters
  ///
  /// - `offset`: Memory offset (pointer)
  /// - `data`: Byte array to write
  ///
  /// ## Throws
  ///
  /// - [RangeError] if offset + data.length exceeds memory size
  ///
  /// ## Example
  ///
  /// ```dart
  /// final data = Uint8List.fromList([1, 2, 3]);
  /// await memory.write(ptr, data);
  /// ```
  Future<void> write(int offset, Uint8List data);

  /// Read bytes synchronously (if supported)
  ///
  /// Synchronous version of [read] for performance-critical code.
  ///
  /// ## Parameters
  ///
  /// - `offset`: Memory offset (pointer)
  /// - `length`: Number of bytes to read
  ///
  /// ## Returns
  ///
  /// Byte array read from memory
  Uint8List readSync(int offset, int length);

  /// Write bytes synchronously (if supported)
  ///
  /// Synchronous version of [write] for performance-critical code.
  ///
  /// ## Parameters
  ///
  /// - `offset`: Memory offset (pointer)
  /// - `data`: Byte array to write
  void writeSync(int offset, Uint8List data);

  /// Grow memory by specified number of pages
  ///
  /// Grows the linear memory by the specified number of 64KB pages.
  ///
  /// ## Parameters
  ///
  /// - `pages`: Number of pages to grow
  ///
  /// ## Returns
  ///
  /// Previous size in pages, or -1 if growth failed
  ///
  /// ## Example
  ///
  /// ```dart
  /// final previousSize = await memory.grow(10); // Grow by 10 pages (640KB)
  /// if (previousSize == -1) {
  ///   print('Memory growth failed');
  /// }
  /// ```
  Future<int> grow(int pages);
}
