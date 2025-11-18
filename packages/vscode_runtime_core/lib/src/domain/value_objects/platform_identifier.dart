import 'package:freezed_annotation/freezed_annotation.dart';

part 'platform_identifier.freezed.dart';

/// Value Object: Platform Identifier
/// Immutable platform identification
@freezed
class PlatformIdentifier with _$PlatformIdentifier {
  const PlatformIdentifier._();

  const factory PlatformIdentifier({
    required String os,
    required String architecture,
  }) = _PlatformIdentifier;

  /// Factory from string (e.g., "windows-x64")
  factory PlatformIdentifier.fromString(String value) {
    final parts = value.split('-');
    if (parts.length != 2) {
      throw FormatException(
        'Platform identifier must be in format: os-architecture',
      );
    }

    final os = parts[0].toLowerCase();
    final arch = parts[1].toLowerCase();

    if (!_validOS.contains(os)) {
      throw FormatException('Invalid OS: $os. Must be one of: $_validOS');
    }

    if (!_validArchitectures.contains(arch)) {
      throw FormatException(
        'Invalid architecture: $arch. Must be one of: $_validArchitectures',
      );
    }

    return PlatformIdentifier(os: os, architecture: arch);
  }

  static const _validOS = ['windows', 'linux', 'macos', 'darwin'];
  static const _validArchitectures = ['x64', 'arm64', 'x86', 'arm'];

  // Well-known platforms
  static final windowsX64 = PlatformIdentifier(os: 'windows', architecture: 'x64');
  static final linuxX64 = PlatformIdentifier(os: 'linux', architecture: 'x64');
  static final macosArm64 = PlatformIdentifier(os: 'macos', architecture: 'arm64');
  static final macosX64 = PlatformIdentifier(os: 'macos', architecture: 'x64');

  /// Get identifier string
  String get identifier => '$os-$architecture';

  /// Get human-readable display string
  String toDisplayString() => identifier;

  /// Check if Windows
  bool get isWindows => os == 'windows';

  /// Check if Linux
  bool get isLinux => os == 'linux';

  /// Check if macOS
  bool get isMacOS => os == 'macos' || os == 'darwin';

  /// Check if ARM architecture
  bool get isARM => architecture.startsWith('arm');

  /// Check if x64 architecture
  bool get isX64 => architecture == 'x64';

  @override
  String toString() => identifier;
}
