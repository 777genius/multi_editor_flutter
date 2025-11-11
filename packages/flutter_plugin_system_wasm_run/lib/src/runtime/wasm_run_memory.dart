import 'dart:typed_data';
import 'package:flutter_plugin_system_wasm/flutter_plugin_system_wasm.dart';

/// WasmRun memory implementation
///
/// Implements IWasmMemory interface using wasm_run's linear memory.
/// Provides read/write access to WASM module's memory space.
///
/// ## Memory Model
///
/// - **Linear Memory**: Contiguous array of bytes
/// - **Page Size**: 64KB (65536 bytes) per page
/// - **Growth**: Can grow by pages
/// - **Isolation**: Isolated from host memory
///
/// ## Example
///
/// ```dart
/// final memory = WasmRunMemory(wasmMemory);
///
/// // Write data
/// final data = Uint8List.fromList([1, 2, 3, 4, 5]);
/// await memory.write(ptr, data);
///
/// // Read data
/// final result = await memory.read(ptr, 5);
/// ```
class WasmRunMemory implements IWasmMemory {
  // TODO: Replace with actual wasm_run memory type when available
  final Object _wasmMemory;

  /// Internal memory buffer (simulated for now)
  /// In production, this would be backed by wasm_run's actual memory
  final ByteData _buffer;

  /// Create wasm_run memory wrapper
  ///
  /// ## Parameters
  ///
  /// - `wasmMemory`: Underlying wasm_run memory object
  WasmRunMemory(this._wasmMemory)
      : _buffer = ByteData(1024 * 1024); // 1MB initial size (simulated)

  @override
  int get size => _buffer.lengthInBytes;

  @override
  int get sizeInPages => (size / 65536).ceil();

  @override
  Future<Uint8List> read(int offset, int length) async {
    return readSync(offset, length);
  }

  @override
  Uint8List readSync(int offset, int length) {
    if (offset < 0 || length < 0) {
      throw RangeError('Offset and length must be non-negative');
    }

    if (offset + length > size) {
      throw RangeError(
        'Read out of bounds: offset=$offset, length=$length, size=$size',
      );
    }

    final result = Uint8List(length);
    for (var i = 0; i < length; i++) {
      result[i] = _buffer.getUint8(offset + i);
    }

    return result;
  }

  @override
  Future<void> write(int offset, Uint8List data) async {
    writeSync(offset, data);
  }

  @override
  void writeSync(int offset, Uint8List data) {
    if (offset < 0) {
      throw RangeError('Offset must be non-negative');
    }

    if (offset + data.length > size) {
      throw RangeError(
        'Write out of bounds: offset=$offset, length=${data.length}, size=$size',
      );
    }

    for (var i = 0; i < data.length; i++) {
      _buffer.setUint8(offset + i, data[i]);
    }
  }

  @override
  Future<int> grow(int pages) async {
    if (pages < 0) {
      throw ArgumentError('Pages must be non-negative');
    }

    final previousPages = sizeInPages;

    // TODO: Implement actual memory growth using wasm_run
    // For now, just return the previous size
    // In production, this would call wasm_run's memory.grow()

    return previousPages;
  }

  /// Get memory view as ByteData
  ///
  /// Returns a view of the memory for direct access.
  /// Use with caution as this bypasses bounds checking.
  ///
  /// ## Returns
  ///
  /// ByteData view of memory
  ByteData get view => _buffer;

  /// Copy memory region
  ///
  /// Copies bytes from one region to another within memory.
  ///
  /// ## Parameters
  ///
  /// - `destOffset`: Destination offset
  /// - `srcOffset`: Source offset
  /// - `length`: Number of bytes to copy
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Copy 100 bytes from offset 0 to offset 1000
  /// memory.copy(destOffset: 1000, srcOffset: 0, length: 100);
  /// ```
  void copy({
    required int destOffset,
    required int srcOffset,
    required int length,
  }) {
    if (destOffset < 0 || srcOffset < 0 || length < 0) {
      throw RangeError('Offsets and length must be non-negative');
    }

    if (srcOffset + length > size || destOffset + length > size) {
      throw RangeError('Copy out of bounds');
    }

    // Read from source
    final data = readSync(srcOffset, length);

    // Write to destination
    writeSync(destOffset, data);
  }

  /// Fill memory region with value
  ///
  /// Fills a region of memory with a repeated byte value.
  ///
  /// ## Parameters
  ///
  /// - `offset`: Starting offset
  /// - `value`: Byte value to fill (0-255)
  /// - `length`: Number of bytes to fill
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Fill 1000 bytes with zeros starting at offset 100
  /// memory.fill(offset: 100, value: 0, length: 1000);
  /// ```
  void fill({
    required int offset,
    required int value,
    required int length,
  }) {
    if (offset < 0 || length < 0) {
      throw RangeError('Offset and length must be non-negative');
    }

    if (value < 0 || value > 255) {
      throw RangeError('Value must be in range 0-255');
    }

    if (offset + length > size) {
      throw RangeError('Fill out of bounds');
    }

    for (var i = 0; i < length; i++) {
      _buffer.setUint8(offset + i, value);
    }
  }

  /// Read integer from memory
  ///
  /// Reads an integer value from memory at the specified offset.
  ///
  /// ## Parameters
  ///
  /// - `offset`: Memory offset
  /// - `endian`: Byte order (default: little endian)
  ///
  /// ## Returns
  ///
  /// Integer value
  ///
  /// ## Example
  ///
  /// ```dart
  /// final value = memory.readInt32(ptr);
  /// ```
  int readInt32(int offset, [Endian endian = Endian.little]) {
    if (offset < 0 || offset + 4 > size) {
      throw RangeError('Read out of bounds');
    }

    return _buffer.getInt32(offset, endian);
  }

  /// Write integer to memory
  ///
  /// Writes an integer value to memory at the specified offset.
  ///
  /// ## Parameters
  ///
  /// - `offset`: Memory offset
  /// - `value`: Integer value to write
  /// - `endian`: Byte order (default: little endian)
  ///
  /// ## Example
  ///
  /// ```dart
  /// memory.writeInt32(ptr, 42);
  /// ```
  void writeInt32(int offset, int value, [Endian endian = Endian.little]) {
    if (offset < 0 || offset + 4 > size) {
      throw RangeError('Write out of bounds');
    }

    _buffer.setInt32(offset, value, endian);
  }

  /// Read 64-bit integer from memory
  int readInt64(int offset, [Endian endian = Endian.little]) {
    if (offset < 0 || offset + 8 > size) {
      throw RangeError('Read out of bounds');
    }

    return _buffer.getInt64(offset, endian);
  }

  /// Write 64-bit integer to memory
  void writeInt64(int offset, int value, [Endian endian = Endian.little]) {
    if (offset < 0 || offset + 8 > size) {
      throw RangeError('Write out of bounds');
    }

    _buffer.setInt64(offset, value, endian);
  }

  /// Read float from memory
  double readFloat32(int offset, [Endian endian = Endian.little]) {
    if (offset < 0 || offset + 4 > size) {
      throw RangeError('Read out of bounds');
    }

    return _buffer.getFloat32(offset, endian);
  }

  /// Write float to memory
  void writeFloat32(int offset, double value, [Endian endian = Endian.little]) {
    if (offset < 0 || offset + 4 > size) {
      throw RangeError('Write out of bounds');
    }

    _buffer.setFloat32(offset, value, endian);
  }

  /// Read double from memory
  double readFloat64(int offset, [Endian endian = Endian.little]) {
    if (offset < 0 || offset + 8 > size) {
      throw RangeError('Read out of bounds');
    }

    return _buffer.getFloat64(offset, endian);
  }

  /// Write double to memory
  void writeFloat64(int offset, double value, [Endian endian = Endian.little]) {
    if (offset < 0 || offset + 8 > size) {
      throw RangeError('Write out of bounds');
    }

    _buffer.setFloat64(offset, value, endian);
  }
}
