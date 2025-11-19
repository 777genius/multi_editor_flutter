import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';

/// Health Check Service Implementation
class HealthCheckService implements IHealthCheckService {
  final Map<String, Future<HealthCheckResult> Function()> _checks = {};
  final Duration _timeout;

  HealthCheckService({
    Duration timeout = const Duration(seconds: 10),
  }) : _timeout = timeout;

  @override
  void registerCheck(
    String componentName,
    Future<HealthCheckResult> Function() checkFunction,
  ) {
    _checks[componentName] = checkFunction;
  }

  @override
  void unregisterCheck(String componentName) {
    _checks.remove(componentName);
  }

  @override
  List<String> getRegisteredComponents() {
    return _checks.keys.toList();
  }

  @override
  Future<Either<DomainException, HealthCheckResult>> checkComponent(
    String componentName,
  ) async {
    try {
      final checkFunction = _checks[componentName];
      if (checkFunction == null) {
        return left(
          DomainException('Health check not registered for $componentName'),
        );
      }

      final result = await checkFunction().timeout(
        _timeout,
        onTimeout: () => HealthCheckResult(
          componentName: componentName,
          status: HealthStatus.unhealthy,
          message: 'Health check timed out after ${_timeout.inSeconds}s',
          timestamp: DateTime.now().toUtc(),
        ),
      );

      return right(result);
    } catch (e) {
      return left(
        DomainException('Health check failed for $componentName: $e'),
      );
    }
  }

  @override
  Future<Either<DomainException, SystemHealth>> checkAll() async {
    try {
      final results = <HealthCheckResult>[];

      // Execute all health checks in parallel
      final futures = _checks.entries.map((entry) async {
        final componentName = entry.key;
        final checkFunction = entry.value;

        try {
          final result = await checkFunction().timeout(
            _timeout,
            onTimeout: () => HealthCheckResult(
              componentName: componentName,
              status: HealthStatus.unhealthy,
              message: 'Health check timed out after ${_timeout.inSeconds}s',
              timestamp: DateTime.now().toUtc(),
            ),
          );
          return result;
        } catch (e) {
          return HealthCheckResult(
            componentName: componentName,
            status: HealthStatus.unhealthy,
            message: 'Health check failed: $e',
            timestamp: DateTime.now().toUtc(),
          );
        }
      });

      results.addAll(await Future.wait(futures));

      // Determine overall status
      final overallStatus = _determineOverallStatus(results);

      final systemHealth = SystemHealth(
        overallStatus: overallStatus,
        componentResults: results,
        timestamp: DateTime.now().toUtc(),
      );

      return right(systemHealth);
    } catch (e) {
      return left(
        DomainException('Failed to check system health: $e'),
      );
    }
  }

  /// Determine overall system health status
  HealthStatus _determineOverallStatus(List<HealthCheckResult> results) {
    if (results.isEmpty) {
      return HealthStatus.healthy;
    }

    final hasUnhealthy = results.any((r) => r.status == HealthStatus.unhealthy);
    final hasDegraded = results.any((r) => r.status == HealthStatus.degraded);

    if (hasUnhealthy) {
      return HealthStatus.unhealthy;
    } else if (hasDegraded) {
      return HealthStatus.degraded;
    } else {
      return HealthStatus.healthy;
    }
  }
}
