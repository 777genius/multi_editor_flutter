import '../plugin_api/plugin_manifest.dart';
import '../versioning/version_constraint.dart';

/// Represents a validation error in the plugin dependency graph
class DependencyValidationError {
  final String pluginId;
  final String message;
  final DependencyErrorType type;

  const DependencyValidationError({
    required this.pluginId,
    required this.message,
    required this.type,
  });

  @override
  String toString() => '[$type] $pluginId: $message';
}

enum DependencyErrorType {
  missingDependency,
  circularDependency,
  incompatibleVersion,
  invalidGraph,
}

/// Dependency with version constraint
class DependencyRequirement {
  final String pluginId;
  final String versionConstraint;

  const DependencyRequirement({
    required this.pluginId,
    required this.versionConstraint,
  });

  factory DependencyRequirement.parse(String depString) {
    // Format: "plugin-id@^1.0.0" or "plugin-id" (any version)
    if (!depString.contains('@')) {
      return DependencyRequirement(pluginId: depString, versionConstraint: '*');
    }

    final parts = depString.split('@');
    return DependencyRequirement(
      pluginId: parts[0],
      versionConstraint: parts.length > 1 ? parts[1] : '*',
    );
  }

  bool isSatisfiedBy(String version) {
    return VersionCompatibility.isCompatible(version, versionConstraint);
  }

  @override
  String toString() => '$pluginId@$versionConstraint';
}

/// Validates plugin dependency graphs
class DependencyValidator {
  final Map<String, PluginManifest> _manifests;

  DependencyValidator(this._manifests);

  /// Validate all dependencies and return errors
  List<DependencyValidationError> validateAll() {
    final errors = <DependencyValidationError>[];

    // Check for missing dependencies
    errors.addAll(_validateMissingDependencies());

    // Check for circular dependencies
    errors.addAll(_validateCircularDependencies());

    // Check for version compatibility
    errors.addAll(_validateVersionCompatibility());

    return errors;
  }

  /// Check if all dependencies are registered
  List<DependencyValidationError> _validateMissingDependencies() {
    final errors = <DependencyValidationError>[];

    for (final entry in _manifests.entries) {
      final pluginId = entry.key;
      final manifest = entry.value;

      for (final depId in manifest.dependencies) {
        if (!_manifests.containsKey(depId)) {
          errors.add(
            DependencyValidationError(
              pluginId: pluginId,
              message: 'Missing dependency: "$depId"',
              type: DependencyErrorType.missingDependency,
            ),
          );
        }
      }
    }

    return errors;
  }

  /// Detect circular dependencies using DFS
  List<DependencyValidationError> _validateCircularDependencies() {
    final errors = <DependencyValidationError>[];
    final visited = <String>{};
    final visiting = <String>{};
    final path = <String>[];

    void visit(String pluginId) {
      if (visited.contains(pluginId)) return;

      if (visiting.contains(pluginId)) {
        // Found cycle
        final cycleStart = path.indexOf(pluginId);
        final cycle = path.sublist(cycleStart)..add(pluginId);
        errors.add(
          DependencyValidationError(
            pluginId: pluginId,
            message: 'Circular dependency: ${cycle.join(" -> ")}',
            type: DependencyErrorType.circularDependency,
          ),
        );
        return;
      }

      visiting.add(pluginId);
      path.add(pluginId);

      final manifest = _manifests[pluginId];
      if (manifest != null) {
        for (final depId in manifest.dependencies) {
          if (_manifests.containsKey(depId)) {
            visit(depId);
          }
        }
      }

      visiting.remove(pluginId);
      visited.add(pluginId);
      path.removeLast();
    }

    for (final pluginId in _manifests.keys) {
      visit(pluginId);
    }

    return errors;
  }

  /// Build a dependency graph for visualization/debugging
  Map<String, List<String>> buildDependencyGraph() {
    final graph = <String, List<String>>{};

    for (final entry in _manifests.entries) {
      graph[entry.key] = List<String>.from(entry.value.dependencies);
    }

    return graph;
  }

  /// Get plugins that have no dependencies (leaves)
  List<String> getLeafPlugins() {
    return _manifests.entries
        .where((e) => e.value.dependencies.isEmpty)
        .map((e) => e.key)
        .toList();
  }

  /// Get plugins that depend on a specific plugin
  List<String> getDependents(String pluginId) {
    return _manifests.entries
        .where((e) => e.value.dependencies.contains(pluginId))
        .map((e) => e.key)
        .toList();
  }

  /// Calculate dependency depth for a plugin
  int getDependencyDepth(String pluginId) {
    final visited = <String>{};

    int calculateDepth(String id) {
      if (visited.contains(id)) return 0;
      visited.add(id);

      final manifest = _manifests[id];
      if (manifest == null || manifest.dependencies.isEmpty) {
        return 0;
      }

      var maxDepth = 0;
      for (final depId in manifest.dependencies) {
        if (_manifests.containsKey(depId)) {
          final depth = calculateDepth(depId) + 1;
          if (depth > maxDepth) maxDepth = depth;
        }
      }

      return maxDepth;
    }

    return calculateDepth(pluginId);
  }

  /// Validate version compatibility between plugins
  List<DependencyValidationError> _validateVersionCompatibility() {
    final errors = <DependencyValidationError>[];

    for (final entry in _manifests.entries) {
      final pluginId = entry.key;
      final manifest = entry.value;

      for (final depString in manifest.dependencies) {
        // Parse dependency requirement (may contain version constraint)
        final requirement = DependencyRequirement.parse(depString);
        final depId = requirement.pluginId;

        // Check if dependency exists
        if (!_manifests.containsKey(depId)) {
          continue; // Already reported by _validateMissingDependencies
        }

        final depManifest = _manifests[depId]!;
        final depVersion = depManifest.version;

        // Check version compatibility
        if (!requirement.isSatisfiedBy(depVersion)) {
          errors.add(
            DependencyValidationError(
              pluginId: pluginId,
              message:
                  'Dependency "$depId" version $depVersion does not satisfy constraint ${requirement.versionConstraint}',
              type: DependencyErrorType.incompatibleVersion,
            ),
          );
        }
      }
    }

    return errors;
  }
}
