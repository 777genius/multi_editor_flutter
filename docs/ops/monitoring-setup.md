# VS Code Runtime Monitoring Setup

## Overview
Complete monitoring and observability setup for production deployment.

## Monitoring Stack

### Core Components
1. **Prometheus** - Metrics collection and alerting
2. **Grafana** - Visualization and dashboards
3. **Sentry** - Error tracking and performance monitoring
4. **Logger** - Structured logging
5. **Alert Manager** - Alert routing and notifications

## Metrics to Monitor

### Application Metrics

```yaml
# Installation metrics
vscode_runtime_installations_total{status="success|failure|cancelled"} counter
vscode_runtime_installation_duration_seconds histogram
vscode_runtime_installation_modules_total counter

# Download metrics
vscode_runtime_downloads_total{status="success|failure"} counter
vscode_runtime_download_size_bytes histogram
vscode_runtime_download_duration_seconds histogram

# Cache metrics
vscode_runtime_cache_hits_total counter
vscode_runtime_cache_misses_total counter
vscode_runtime_cache_entries{type="valid|expired"} gauge
vscode_runtime_cache_size_bytes gauge

# Error metrics
vscode_runtime_errors_total{type="domain|application|infrastructure"} counter
vscode_runtime_error_rate{severity="warning|error|fatal"} gauge
```

### Infrastructure Metrics

```yaml
# Network metrics
vscode_runtime_network_requests_total{service="manifest|download"} counter
vscode_runtime_network_request_duration_seconds histogram
vscode_runtime_network_errors_total{error_type="timeout|connection|5xx"} counter

# Circuit breaker metrics
vscode_runtime_circuit_breaker_state{circuit="manifest|download"} gauge  # 0=closed, 1=open, 0.5=half-open
vscode_runtime_circuit_breaker_transitions_total{circuit,from,to} counter
vscode_runtime_circuit_breaker_failures_total{circuit} counter

# Rate limiter metrics
vscode_runtime_rate_limiter_queued_requests gauge
vscode_runtime_rate_limiter_rejected_requests_total counter
vscode_runtime_rate_limiter_active_requests gauge

# Health check metrics
vscode_runtime_health_status{component} gauge  # 1=healthy, 0.5=degraded, 0=unhealthy
vscode_runtime_health_check_duration_seconds{component} histogram
```

### System Metrics

```yaml
# Resource usage
vscode_runtime_cpu_usage_percent gauge
vscode_runtime_memory_usage_bytes gauge
vscode_runtime_disk_free_bytes{path="/tmp/vscode_runtime_downloads"} gauge
vscode_runtime_disk_used_bytes{path="/tmp/vscode_runtime_downloads"} gauge

# Process metrics
vscode_runtime_process_uptime_seconds gauge
vscode_runtime_process_restarts_total counter
```

## Prometheus Configuration

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'production'
    service: 'vscode_runtime'

scrape_configs:
  - job_name: 'vscode_runtime'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'vscode_runtime_health'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: '/health'
    scrape_interval: 60s

# Alert rules
rule_files:
  - 'alerts/*.yml'
```

## Alert Rules

### Critical Alerts

```yaml
# alerts/critical.yml
groups:
  - name: critical
    interval: 30s
    rules:
      # Installation failure rate > 10%
      - alert: HighInstallationFailureRate
        expr: |
          rate(vscode_runtime_installations_total{status="failure"}[5m]) /
          rate(vscode_runtime_installations_total[5m]) > 0.1
        for: 5m
        labels:
          severity: critical
          team: runtime
        annotations:
          summary: "High installation failure rate"
          description: "{{ $value | humanizePercentage }} of installations failing"
          runbook: "https://docs.example.com/runbooks/installation-failure-recovery"

      # Circuit breaker open
      - alert: CircuitBreakerOpen
        expr: vscode_runtime_circuit_breaker_state > 0.5
        for: 2m
        labels:
          severity: critical
          team: runtime
        annotations:
          summary: "Circuit breaker {{ $labels.circuit }} is open"
          description: "Circuit breaker protecting {{ $labels.circuit }} has opened"
          runbook: "https://docs.example.com/runbooks/circuit-breaker-recovery"

      # Component unhealthy
      - alert: ComponentUnhealthy
        expr: vscode_runtime_health_status < 0.5
        for: 1m
        labels:
          severity: critical
          team: runtime
        annotations:
          summary: "Component {{ $labels.component }} unhealthy"
          description: "Component is completely down"
          runbook: "https://docs.example.com/runbooks/health-check-guide"

      # High error rate
      - alert: HighErrorRate
        expr: |
          rate(vscode_runtime_errors_total[5m]) > 10
        for: 5m
        labels:
          severity: critical
          team: runtime
        annotations:
          summary: "High error rate detected"
          description: "{{ $value }} errors per second"
          runbook: "https://docs.example.com/runbooks/error-investigation"

      # Disk space critical
      - alert: DiskSpaceCritical
        expr: vscode_runtime_disk_free_bytes < 500e6  # 500MB
        for: 5m
        labels:
          severity: critical
          team: infrastructure
        annotations:
          summary: "Critical low disk space"
          description: "Only {{ $value | humanize }}B free"
          runbook: "https://docs.example.com/runbooks/disk-space-management"
```

### Warning Alerts

```yaml
# alerts/warning.yml
groups:
  - name: warning
    interval: 60s
    rules:
      # Component degraded
      - alert: ComponentDegraded
        expr: vscode_runtime_health_status < 1 and vscode_runtime_health_status >= 0.5
        for: 10m
        labels:
          severity: warning
          team: runtime
        annotations:
          summary: "Component {{ $labels.component }} degraded"
          description: "Performance impacted but functional"

      # High cache miss rate
      - alert: HighCacheMissRate
        expr: |
          rate(vscode_runtime_cache_misses_total[10m]) /
          (rate(vscode_runtime_cache_hits_total[10m]) +
           rate(vscode_runtime_cache_misses_total[10m])) > 0.5
        for: 15m
        labels:
          severity: warning
          team: runtime
        annotations:
          summary: "High cache miss rate"
          description: "{{ $value | humanizePercentage }} cache misses"

      # Slow downloads
      - alert: SlowDownloads
        expr: |
          histogram_quantile(0.95,
            rate(vscode_runtime_download_duration_seconds_bucket[5m])
          ) > 300  # 5 minutes
        for: 10m
        labels:
          severity: warning
          team: runtime
        annotations:
          summary: "Downloads are slow"
          description: "P95 download time: {{ $value }}s"

      # Network retry rate high
      - alert: HighNetworkRetryRate
        expr: |
          rate(vscode_runtime_network_retries_total[5m]) > 5
        for: 10m
        labels:
          severity: warning
          team: infrastructure
        annotations:
          summary: "High network retry rate"
          description: "{{ $value }} retries per second"

      # Disk space warning
      - alert: DiskSpaceWarning
        expr: vscode_runtime_disk_free_bytes < 1e9  # 1GB
        for: 15m
        labels:
          severity: warning
          team: infrastructure
        annotations:
          summary: "Low disk space"
          description: "Only {{ $value | humanize }}B free"
```

## Grafana Dashboards

### Main Dashboard

```json
{
  "dashboard": {
    "title": "VS Code Runtime - Overview",
    "panels": [
      {
        "title": "Installation Success Rate",
        "type": "gauge",
        "targets": [{
          "expr": "rate(vscode_runtime_installations_total{status=\"success\"}[5m]) / rate(vscode_runtime_installations_total[5m])"
        }],
        "thresholds": [
          {"value": 0.95, "color": "green"},
          {"value": 0.90, "color": "yellow"},
          {"value": 0, "color": "red"}
        ]
      },
      {
        "title": "Active Installations",
        "type": "stat",
        "targets": [{
          "expr": "vscode_runtime_installations_active"
        }]
      },
      {
        "title": "Installation Duration (P95)",
        "type": "graph",
        "targets": [{
          "expr": "histogram_quantile(0.95, rate(vscode_runtime_installation_duration_seconds_bucket[5m]))"
        }]
      },
      {
        "title": "Component Health",
        "type": "heatmap",
        "targets": [{
          "expr": "vscode_runtime_health_status"
        }]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "targets": [{
          "expr": "rate(vscode_runtime_errors_total[5m])"
        }]
      },
      {
        "title": "Cache Hit Rate",
        "type": "gauge",
        "targets": [{
          "expr": "rate(vscode_runtime_cache_hits_total[5m]) / (rate(vscode_runtime_cache_hits_total[5m]) + rate(vscode_runtime_cache_misses_total[5m]))"
        }]
      },
      {
        "title": "Circuit Breaker States",
        "type": "stat",
        "targets": [{
          "expr": "vscode_runtime_circuit_breaker_state"
        }]
      },
      {
        "title": "Download Throughput",
        "type": "graph",
        "targets": [{
          "expr": "rate(vscode_runtime_download_size_bytes_sum[5m])"
        }]
      }
    ]
  }
}
```

## Sentry Configuration

```dart
// main.dart
Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://YOUR_DSN@sentry.io/PROJECT_ID';
      options.environment = 'production';
      options.release = 'vscode-runtime@1.0.0';
      options.tracesSampleRate = 0.1;  // 10% of transactions
      options.profilesSampleRate = 0.1;  // 10% of transactions

      // Custom tags
      options.beforeSend = (event, hint) {
        event.tags = {
          ...?event.tags,
          'component': 'vscode_runtime',
          'platform': Platform.operatingSystem,
        };
        return event;
      };

      // Filter sensitive data
      options.beforeBreadcrumb = (breadcrumb, hint) {
        if (breadcrumb.data?['url']?.contains('secret')) {
          return null;  // Don't send
        }
        return breadcrumb;
      };
    },
    appRunner: () => runApp(MyApp()),
  );
}
```

## Logging Configuration

```dart
// Initialize logging
final logger = LoggingService(
  logLevel: Level.info,  // production level
  enableColors: false,
);

// Log rotation
final logFile = File('/var/log/vscode_runtime/app.log');
final logSink = logFile.openWrite(mode: FileMode.append);

// Structured logging
logger.info(
  'Installation started',
  {
    'installationId': installationId.value,
    'moduleCount': modules.length,
    'trigger': trigger.name,
  },
);
```

## Alert Channels

### Slack Integration

```yaml
# alertmanager.yml
receivers:
  - name: 'slack-critical'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
        channel: '#runtime-critical'
        title: '🚨 {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
        send_resolved: true

  - name: 'slack-warning'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
        channel: '#runtime-warnings'
        title: '⚠️ {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

route:
  receiver: 'slack-warning'
  group_by: ['alertname']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  routes:
    - match:
        severity: critical
      receiver: 'slack-critical'
      repeat_interval: 30m
```

### PagerDuty Integration

```yaml
receivers:
  - name: 'pagerduty'
    pagerduty_configs:
      - service_key: 'YOUR_SERVICE_KEY'
        description: '{{ .GroupLabels.alertname }}: {{ .GroupLabels.severity }}'

route:
  routes:
    - match:
        severity: critical
      receiver: 'pagerduty'
      continue: true  # Also send to Slack
```

## Deployment Checklist

- [ ] Prometheus installed and configured
- [ ] Grafana dashboards imported
- [ ] Alert rules deployed
- [ ] AlertManager configured
- [ ] Sentry project created and DSN configured
- [ ] Log rotation configured
- [ ] Slack webhooks tested
- [ ] PagerDuty integration tested (if applicable)
- [ ] Test alerts sent and received
- [ ] Runbooks linked in alerts
- [ ] Team trained on alert response

## Related Documentation

- [Health Check Guide](../runbooks/health-check-guide.md)
- [Installation Failure Recovery](../runbooks/installation-failure-recovery.md)
- [Deployment Guide](./deployment-guide.md)

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-19 | Claude | Initial version |
