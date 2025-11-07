import '../entities/file_icon.dart';
import '../value_objects/file_extension.dart';

/// Repository interface for icon data access.
///
/// In Clean Architecture, repositories are defined in the domain layer
/// but implemented in the infrastructure layer.
///
/// This follows the Dependency Inversion Principle (SOLID).
abstract class IconRepository {
  /// Get icon for a specific file extension.
  ///
  /// Returns null if no icon is available for this extension.
  Future<FileIcon?> getIcon(FileExtension extension);

  /// Get icons for multiple extensions at once (batch operation).
  ///
  /// More efficient than calling getIcon multiple times.
  Future<Map<FileExtension, FileIcon>> getIcons(List<FileExtension> extensions);

  /// Check if an icon exists for the given extension.
  Future<bool> hasIcon(FileExtension extension);

  /// Clear cached icons (if repository uses caching).
  Future<void> clearCache();

  /// Get statistics about cached icons.
  Future<IconRepositoryStats> getStats();
}

/// Statistics about icon repository state.
class IconRepositoryStats {
  final int cachedIconsCount;
  final int totalRequests;
  final int cacheHits;
  final int cacheMisses;
  final int failedRequests;

  const IconRepositoryStats({
    required this.cachedIconsCount,
    required this.totalRequests,
    required this.cacheHits,
    required this.cacheMisses,
    required this.failedRequests,
  });

  double get cacheHitRate =>
      totalRequests > 0 ? cacheHits / totalRequests : 0.0;

  double get failureRate =>
      totalRequests > 0 ? failedRequests / totalRequests : 0.0;
}
