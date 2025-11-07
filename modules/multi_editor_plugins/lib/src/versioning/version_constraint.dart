/// Simple semantic version parser (X.Y.Z format)
/// Avoids pub_semver for dart2js compatibility
class _SemVersion implements Comparable<_SemVersion> {
  final int major;
  final int minor;
  final int patch;

  const _SemVersion(this.major, this.minor, this.patch);

  factory _SemVersion.parse(String version) {
    final parts = version.split('.');
    if (parts.isEmpty || parts.length > 3) {
      throw FormatException('Invalid version format: $version');
    }

    final major = int.parse(parts[0]);
    final minor = parts.length > 1 ? int.parse(parts[1]) : 0;
    final patch = parts.length > 2 ? int.parse(parts[2]) : 0;

    return _SemVersion(major, minor, patch);
  }

  @override
  int compareTo(_SemVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator >(_SemVersion other) => compareTo(other) > 0;
  bool operator <(_SemVersion other) => compareTo(other) < 0;
  bool operator >=(_SemVersion other) => compareTo(other) >= 0;
  bool operator <=(_SemVersion other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) =>
      other is _SemVersion &&
      major == other.major &&
      minor == other.minor &&
      patch == other.patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}

/// Version compatibility checker for plugins
class VersionCompatibility {
  /// Check if plugin version satisfies dependency constraint
  static bool isCompatible(String pluginVersion, String dependencyConstraint) {
    try {
      // Handle wildcard
      if (dependencyConstraint == '*' || dependencyConstraint.isEmpty) {
        return true;
      }

      final version = _SemVersion.parse(pluginVersion);

      // Handle caret constraint: ^1.2.3 allows >=1.2.3 <2.0.0
      if (dependencyConstraint.startsWith('^')) {
        final constraintVersion =
            _SemVersion.parse(dependencyConstraint.substring(1));
        return version >= constraintVersion &&
            version.major == constraintVersion.major;
      }

      // Handle tilde constraint: ~1.2.3 allows >=1.2.3 <1.3.0
      if (dependencyConstraint.startsWith('~')) {
        final constraintVersion =
            _SemVersion.parse(dependencyConstraint.substring(1));
        return version >= constraintVersion &&
            version.major == constraintVersion.major &&
            version.minor == constraintVersion.minor;
      }

      // Handle comparison operators
      if (dependencyConstraint.startsWith('>=')) {
        final constraintVersion =
            _SemVersion.parse(dependencyConstraint.substring(2).trim());
        return version >= constraintVersion;
      }

      if (dependencyConstraint.startsWith('<=')) {
        final constraintVersion =
            _SemVersion.parse(dependencyConstraint.substring(2).trim());
        return version <= constraintVersion;
      }

      if (dependencyConstraint.startsWith('>')) {
        final constraintVersion =
            _SemVersion.parse(dependencyConstraint.substring(1).trim());
        return version > constraintVersion;
      }

      if (dependencyConstraint.startsWith('<')) {
        final constraintVersion =
            _SemVersion.parse(dependencyConstraint.substring(1).trim());
        return version < constraintVersion;
      }

      if (dependencyConstraint.startsWith('=')) {
        final constraintVersion =
            _SemVersion.parse(dependencyConstraint.substring(1).trim());
        return version == constraintVersion;
      }

      // Default: exact match
      final constraintVersion = _SemVersion.parse(dependencyConstraint);
      return version == constraintVersion;
    } catch (e) {
      // If parsing fails, assume compatible
      return true;
    }
  }

  /// Check if two versions are API compatible (same major version)
  static bool isApiCompatible(String version1, String version2) {
    try {
      final v1 = _SemVersion.parse(version1);
      final v2 = _SemVersion.parse(version2);
      return v1.major == v2.major;
    } catch (e) {
      return false;
    }
  }

  /// Compare two versions
  static int compare(String version1, String version2) {
    try {
      final v1 = _SemVersion.parse(version1);
      final v2 = _SemVersion.parse(version2);
      return v1.compareTo(v2);
    } catch (e) {
      return 0;
    }
  }

  /// Check if version1 is newer than version2
  static bool isNewer(String version1, String version2) {
    return compare(version1, version2) > 0;
  }

  /// Get breaking changes between versions
  static BreakingChangeType getBreakingChangeType(
    String oldVersion,
    String newVersion,
  ) {
    try {
      final v1 = _SemVersion.parse(oldVersion);
      final v2 = _SemVersion.parse(newVersion);

      if (v2.major > v1.major) {
        return BreakingChangeType.major;
      } else if (v2.minor > v1.minor) {
        return BreakingChangeType.minor;
      } else if (v2.patch > v1.patch) {
        return BreakingChangeType.patch;
      }
      return BreakingChangeType.none;
    } catch (e) {
      return BreakingChangeType.unknown;
    }
  }
}

enum BreakingChangeType {
  none,
  patch, // Bug fixes
  minor, // New features, backwards compatible
  major, // Breaking changes
  unknown,
}

extension BreakingChangeTypeExtension on BreakingChangeType {
  bool get isBreaking => this == BreakingChangeType.major;
  bool get hasNewFeatures =>
      this == BreakingChangeType.minor || this == BreakingChangeType.major;

  String get description {
    switch (this) {
      case BreakingChangeType.none:
        return 'No changes';
      case BreakingChangeType.patch:
        return 'Bug fixes only';
      case BreakingChangeType.minor:
        return 'New features (backwards compatible)';
      case BreakingChangeType.major:
        return 'Breaking changes';
      case BreakingChangeType.unknown:
        return 'Unknown changes';
    }
  }
}
