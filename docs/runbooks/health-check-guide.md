# Runbook: Health Check & Monitoring Guide

## Overview
This runbook covers health check monitoring, interpretation, and actions for the VS Code Runtime system.

## Health Check Architecture

### Components Monitored

1. **Manifest Service** (`manifest_endpoint`)
   - Checks: Manifest endpoint reachability
   - Timeout: 10s
   - Healthy: HTTP 200, valid JSON
   - Degraded: Slow response (> 5s)
   - Unhealthy: Timeout, HTTP 5xx, invalid JSON

2. **Download Service** (`download_service`)
   - Checks: CDN connectivity, write permissions
   - Timeout: 10s
   - Healthy: Can reach CDN, write to disk
   - Degraded: Slow CDN response
   - Unhealthy: CDN unreachable, no write permissions

3. **File System** (`file_system`)
   - Checks: Disk space, write permissions
   - Timeout: 5s
   - Healthy: > 1GB free space, write OK
   - Degraded: < 1GB but > 500MB free
   - Unhealthy: < 500MB or no write permissions

4. **Event Bus** (`event_bus`)
   - Checks: Event publishing and subscription
   - Timeout: 5s
   - Healthy: Events flow correctly
   - Degraded: Slow event processing
   - Unhealthy: Events not delivered

5. **Cache Service** (`cache`)
   - Checks: Read/write operations, expiration
   - Timeout: 5s
   - Healthy: Cache operations work
   - Degraded: High cache miss rate
   - Unhealthy: Cache unavailable

6. **Circuit Breakers** (`circuit_breakers`)
   - Checks: Circuit breaker states
   - Healthy: All closed
   - Degraded: Some half-open
   - Unhealthy: Critical circuits open

## Health Check Endpoints

### System Health
```bash
GET /health

Response:
{
  "overallStatus": "healthy|degraded|unhealthy",
  "timestamp": "2025-11-19T10:30:00Z",
  "summary": {
    "total": 6,
    "healthy": 5,
    "degraded": 1,
    "unhealthy": 0
  },
  "components": [
    {
      "component": "manifest_endpoint",
      "status": "healthy",
      "message": "Manifest endpoint reachable",
      "responseTime": 150,
      "timestamp": "2025-11-19T10:30:00Z"
    },
    {
      "component": "download_service",
      "status": "degraded",
      "message": "CDN response slow (5500ms)",
      "responseTime": 5500,
      "timestamp": "2025-11-19T10:30:00Z"
    }
  ]
}
```

### Individual Component Health
```bash
GET /health/manifest_endpoint
GET /health/download_service
GET /health/file_system
GET /health/event_bus
GET /health/cache
GET /health/circuit_breakers
```

## Interpreting Health Status

### Overall Status Logic

```
IF any component = unhealthy THEN overall = unhealthy
ELSE IF any component = degraded THEN overall = degraded
ELSE overall = healthy
```

### Status Meanings

**Healthy (Green)**
- All systems operational
- No action needed
- Continue normal operations

**Degraded (Yellow)**
- System operational but performance impacted
- Users may experience slowdowns
- **Action**: Investigate within 1 hour
- **Alert**: Warning level

**Unhealthy (Red)**
- Critical functionality impaired
- Users may be unable to complete operations
- **Action**: Investigate immediately
- **Alert**: Critical level

## Common Health Issues

### Issue 1: Manifest Endpoint Unhealthy

**Symptoms:**
```json
{
  "component": "manifest_endpoint",
  "status": "unhealthy",
  "message": "Connection timeout after 10s"
}
```

**Diagnosis:**
```bash
# Test manifest endpoint directly
curl -w "@curl-format.txt" https://cdn.example.com/manifest.json

# Check circuit breaker
curl http://localhost:8080/health/circuit_breakers | jq '.metadata.manifest_circuit'
```

**Actions:**
1. Check CDN status
2. Verify network connectivity
3. Check circuit breaker state
4. If circuit open, wait for cooldown or manual reset
5. Check for upstream incidents

---

### Issue 2: File System Degraded

**Symptoms:**
```json
{
  "component": "file_system",
  "status": "degraded",
  "message": "Low disk space: 800MB free",
  "metadata": {
    "availableSpace": 800000000,
    "threshold": 1000000000
  }
}
```

**Diagnosis:**
```bash
# Check disk space
df -h /tmp/vscode_runtime_downloads

# Check for large files
du -sh /tmp/vscode_runtime_downloads/* | sort -h
```

**Actions:**
1. Clean up old downloads:
   ```bash
   find /tmp/vscode_runtime_downloads -mtime +7 -delete
   ```
2. Clear cache:
   ```bash
   curl -X DELETE http://localhost:8080/api/cache
   ```
3. If persistent, increase disk quota

---

### Issue 3: Cache Service Degraded

**Symptoms:**
```json
{
  "component": "cache",
  "status": "degraded",
  "message": "High cache miss rate: 75%",
  "metadata": {
    "hitRate": 0.25,
    "missRate": 0.75,
    "expired": 50
  }
}
```

**Diagnosis:**
```bash
# Check cache stats
curl http://localhost:8080/api/cache/stats

# Response:
{
  "total": 100,
  "valid": 25,
  "expired": 75
}
```

**Actions:**
1. Remove expired entries:
   ```bash
   curl -X POST http://localhost:8080/api/cache/cleanup
   ```
2. Check if TTL too short (should be 24h for manifest)
3. Monitor hit rate after cleanup
4. If persistent, investigate access patterns

---

### Issue 4: Circuit Breaker Open

**Symptoms:**
```json
{
  "component": "circuit_breakers",
  "status": "unhealthy",
  "message": "Critical circuit breaker open: download_circuit",
  "metadata": {
    "download_circuit": {
      "state": "open",
      "failureCount": 5,
      "failureThreshold": 5,
      "lastFailureTime": "2025-11-19T10:25:00Z"
    }
  }
}
```

**Diagnosis:**
```bash
# Get circuit breaker details
curl http://localhost:8080/health/circuit_breakers | jq

# Check recent errors
tail -100 /var/log/vscode_runtime/infrastructure.log | grep "circuit breaker"
```

**Actions:**
1. Identify root cause of failures
2. Fix underlying issue (network, CDN, etc.)
3. Wait for automatic recovery (60s for downloads)
4. Or manual reset:
   ```bash
   curl -X POST http://localhost:8080/api/circuit-breaker/reset/download_circuit
   ```
5. Monitor for recurrence

---

## Monitoring Setup

### Prometheus Metrics

```yaml
# Health check metrics
vscode_runtime_health_status{component="manifest_endpoint"} 1  # 1=healthy, 0.5=degraded, 0=unhealthy
vscode_runtime_health_response_time{component="manifest_endpoint"} 150
vscode_runtime_health_checks_total{component="manifest_endpoint",status="success"} 1000
vscode_runtime_health_checks_total{component="manifest_endpoint",status="failure"} 5

# Circuit breaker metrics
vscode_runtime_circuit_breaker_state{circuit="download"} 0  # 0=closed, 1=open, 0.5=half-open
vscode_runtime_circuit_breaker_failures{circuit="download"} 5
vscode_runtime_circuit_breaker_successes{circuit="download"} 995

# Cache metrics
vscode_runtime_cache_hit_rate 0.85
vscode_runtime_cache_entries{type="valid"} 75
vscode_runtime_cache_entries{type="expired"} 25
```

### Grafana Dashboard

**Panels:**
1. Overall Health Status (single stat)
2. Component Health Matrix (heatmap)
3. Response Times (time series)
4. Circuit Breaker States (gauge)
5. Cache Hit Rate (gauge)
6. Disk Space (gauge)

### Alert Rules

```yaml
# Critical: Any component unhealthy
- alert: ComponentUnhealthy
  expr: vscode_runtime_health_status < 0.5
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "Component {{ $labels.component }} is unhealthy"

# Warning: Any component degraded
- alert: ComponentDegraded
  expr: vscode_runtime_health_status < 1 and vscode_runtime_health_status >= 0.5
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Component {{ $labels.component }} is degraded"

# Critical: Circuit breaker open
- alert: CircuitBreakerOpen
  expr: vscode_runtime_circuit_breaker_state > 0.5
  for: 2m
  labels:
    severity: critical
  annotations:
    summary: "Circuit breaker {{ $labels.circuit }} is open"

# Warning: Low disk space
- alert: LowDiskSpace
  expr: vscode_runtime_disk_free_bytes < 1e9
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Low disk space: {{ $value | humanize }}B"
```

## Health Check Best Practices

### 1. Regular Testing
- Test health checks in staging
- Simulate failure scenarios
- Verify alert delivery

### 2. Appropriate Timeouts
- Keep timeouts reasonable (5-10s)
- Don't overload system with checks
- Run checks every 30-60 seconds

### 3. Meaningful Messages
- Include actionable information
- Provide context in metadata
- Link to relevant runbooks

### 4. Status Page Integration
- Publish aggregate health to status page
- Update during incidents
- Communicate clearly with users

### 5. Dependency Tracking
- Know which components depend on others
- Understand cascade effects
- Prioritize critical paths

## Troubleshooting Workflow

```
1. Receive Alert
   ↓
2. Check Health Endpoint
   ↓
3. Identify Unhealthy Component
   ↓
4. Run Component-Specific Diagnostics
   ↓
5. Apply Remediation (see component-specific actions)
   ↓
6. Verify Health Restored
   ↓
7. Document Incident
   ↓
8. Implement Prevention
```

## Related Documentation

- [Installation Failure Recovery](./installation-failure-recovery.md)
- [Network Troubleshooting](./network-troubleshooting.md)
- [Cache Management](./cache-management.md)
- [Monitoring Setup](../ops/monitoring-setup.md)

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-19 | Claude | Initial version |
