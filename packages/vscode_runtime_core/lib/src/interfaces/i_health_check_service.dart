import 'package:dartz/dartz.dart';
import '../domain/exceptions/domain_exception.dart';

/// Health Check Status
enum HealthStatus {
  healthy,
  degraded,
  unhealthy,
}

/// Health Check Result
class HealthCheckResult {
  final String componentName;
  final HealthStatus status;
  final String? message;
  final DateTime timestamp;
  final Duration? responseTime;
  final Map<String, dynamic>? metadata;

  const HealthCheckResult({
    required this.componentName,
    required this.status,
    this.message,
    required this.timestamp,
    this.responseTime,
    this.metadata,
  });

  bool get isHealthy => status == HealthStatus.healthy;
  bool get isDegraded => status == HealthStatus.degraded;
  bool get isUnhealthy => status == HealthStatus.unhealthy;

  Map<String, dynamic> toJson() => {
        'component': componentName,
        'status': status.name,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'responseTime': responseTime?.inMilliseconds,
        'metadata': metadata,
      };
}

/// Overall System Health
class SystemHealth {
  final HealthStatus overallStatus;
  final List<HealthCheckResult> componentResults;
  final DateTime timestamp;

  const SystemHealth({
    required this.overallStatus,
    required this.componentResults,
    required this.timestamp,
  });

  bool get isHealthy => overallStatus == HealthStatus.healthy;
  bool get isDegraded => overallStatus == HealthStatus.degraded;
  bool get isUnhealthy => overallStatus == HealthStatus.unhealthy;

  int get healthyCount =>
      componentResults.where((r) => r.isHealthy).length;

  int get degradedCount =>
      componentResults.where((r) => r.isDegraded).length;

  int get unhealthyCount =>
      componentResults.where((r) => r.isUnhealthy).length;

  Map<String, dynamic> toJson() => {
        'overallStatus': overallStatus.name,
        'timestamp': timestamp.toIso8601String(),
        'summary': {
          'healthy': healthyCount,
          'degraded': degradedCount,
          'unhealthy': unhealthyCount,
          'total': componentResults.length,
        },
        'components': componentResults.map((r) => r.toJson()).toList(),
      };
}

/// Health Check Service Interface
abstract class IHealthCheckService {
  /// Check health of a specific component
  Future<Either<DomainException, HealthCheckResult>> checkComponent(
    String componentName,
  );

  /// Check health of all registered components
  Future<Either<DomainException, SystemHealth>> checkAll();

  /// Register a health check for a component
  void registerCheck(
    String componentName,
    Future<HealthCheckResult> Function() checkFunction,
  );

  /// Unregister a health check
  void unregisterCheck(String componentName);

  /// Get list of registered components
  List<String> getRegisteredComponents();
}
