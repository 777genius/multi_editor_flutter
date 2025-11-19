# VS Code Runtime Deployment Guide

## Overview
Complete deployment guide for VS Code Runtime system in production.

## Prerequisites

### System Requirements
- **OS**: Linux (Ubuntu 20.04+ or equivalent)
- **Runtime**: Dart SDK 3.5.0+
- **Memory**: 2GB minimum, 4GB recommended
- **Disk**: 10GB minimum, 20GB recommended
- **Network**: Stable internet connection for CDN access

### Dependencies
```bash
# Install Dart SDK
sudo apt-get update
sudo apt-get install apt-transport-https
wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/dart.gpg
echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | sudo tee /etc/apt/sources.list.d/dart_stable.list
sudo apt-get update
sudo apt-get install dart

# Install system dependencies
sudo apt-get install -y \
  curl \
  git \
  unzip \
  ca-certificates
```

## Build Process

### 1. Clone Repository
```bash
git clone https://github.com/yourorg/multi_editor_flutter.git
cd multi_editor_flutter
```

### 2. Install Package Dependencies
```bash
# Install dependencies for all packages
cd packages/vscode_runtime_core
dart pub get
cd ../vscode_runtime_application
dart pub get
cd ../vscode_runtime_infrastructure
dart pub get
cd ../vscode_runtime_presentation
dart pub get
cd ../..
```

### 3. Generate Code
```bash
# Generate freezed, json_serializable, and injectable code
cd packages/vscode_runtime_core
dart run build_runner build --delete-conflicting-outputs

cd ../vscode_runtime_infrastructure
dart run build_runner build --delete-conflicting-outputs

cd ../vscode_runtime_application
dart run build_runner build --delete-conflicting-outputs

cd ../vscode_runtime_presentation
dart run build_runner build --delete-conflicting-outputs

cd ../..
```

### 4. Run Tests
```bash
# Run all tests
cd packages/vscode_runtime_core
dart test

cd ../vscode_runtime_application
dart test

cd ../vscode_runtime_infrastructure
dart test

cd ../..
```

### 5. Build Application
```bash
# Build production binary
dart compile exe app/bin/main.dart -o build/vscode_runtime

# Verify build
./build/vscode_runtime --version
```

## Deployment Options

### Option 1: Systemd Service (Recommended)

#### Create Service File
```bash
sudo nano /etc/systemd/system/vscode-runtime.service
```

```ini
[Unit]
Description=VS Code Runtime Management Service
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=vscode-runtime
Group=vscode-runtime
WorkingDirectory=/opt/vscode-runtime
ExecStart=/opt/vscode-runtime/bin/vscode_runtime
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
Environment="DART_VM_OPTIONS=--old_gen_heap_size=2048"

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/vscode-runtime /var/log/vscode-runtime

[Install]
WantedBy=multi-user.target
```

#### Deploy and Start
```bash
# Create user
sudo useradd --system --shell /bin/false vscode-runtime

# Create directories
sudo mkdir -p /opt/vscode-runtime/bin
sudo mkdir -p /var/lib/vscode-runtime
sudo mkdir -p /var/log/vscode-runtime

# Copy binary
sudo cp build/vscode_runtime /opt/vscode-runtime/bin/

# Set permissions
sudo chown -R vscode-runtime:vscode-runtime /opt/vscode-runtime
sudo chown -R vscode-runtime:vscode-runtime /var/lib/vscode-runtime
sudo chown -R vscode-runtime:vscode-runtime /var/log/vscode-runtime

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable vscode-runtime
sudo systemctl start vscode-runtime

# Check status
sudo systemctl status vscode-runtime
sudo journalctl -u vscode-runtime -f
```

### Option 2: Docker Container

#### Dockerfile
```dockerfile
FROM dart:3.5-sdk AS build

# Copy source
WORKDIR /app
COPY . .

# Install dependencies
RUN cd packages/vscode_runtime_core && dart pub get && \
    cd ../vscode_runtime_application && dart pub get && \
    cd ../vscode_runtime_infrastructure && dart pub get && \
    cd ../vscode_runtime_presentation && dart pub get

# Generate code
RUN cd packages/vscode_runtime_core && dart run build_runner build --delete-conflicting-outputs && \
    cd ../vscode_runtime_infrastructure && dart run build_runner build --delete-conflicting-outputs && \
    cd ../vscode_runtime_application && dart run build_runner build --delete-conflicting-outputs && \
    cd ../vscode_runtime_presentation && dart run build_runner build --delete-conflicting-outputs

# Build binary
RUN dart compile exe app/bin/main.dart -o /app/vscode_runtime

# Runtime stage
FROM debian:bullseye-slim

RUN apt-get update && \
    apt-get install -y ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd --create-home --shell /bin/bash vscode-runtime

# Copy binary
COPY --from=build /app/vscode_runtime /usr/local/bin/vscode_runtime
RUN chmod +x /usr/local/bin/vscode_runtime

# Set up directories
RUN mkdir -p /var/lib/vscode-runtime /var/log/vscode-runtime && \
    chown -R vscode-runtime:vscode-runtime /var/lib/vscode-runtime /var/log/vscode-runtime

USER vscode-runtime
WORKDIR /var/lib/vscode-runtime

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080

CMD ["/usr/local/bin/vscode_runtime"]
```

#### Docker Compose
```yaml
version: '3.8'

services:
  vscode-runtime:
    build: .
    container_name: vscode-runtime
    ports:
      - "8080:8080"
    volumes:
      - runtime-data:/var/lib/vscode-runtime
      - runtime-logs:/var/log/vscode-runtime
    environment:
      - DART_VM_OPTIONS=--old_gen_heap_size=2048
      - SENTRY_DSN=${SENTRY_DSN}
      - MANIFEST_URL=${MANIFEST_URL}
    restart: unless-stopped
    networks:
      - runtime-net
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  runtime-data:
  runtime-logs:

networks:
  runtime-net:
    driver: bridge
```

#### Deploy with Docker
```bash
# Build image
docker-compose build

# Start service
docker-compose up -d

# Check logs
docker-compose logs -f

# Check health
curl http://localhost:8080/health
```

### Option 3: Kubernetes Deployment

#### Deployment Manifest
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vscode-runtime
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: vscode-runtime
  template:
    metadata:
      labels:
        app: vscode-runtime
        version: v1.0.0
    spec:
      containers:
      - name: vscode-runtime
        image: yourregistry/vscode-runtime:1.0.0
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: DART_VM_OPTIONS
          value: "--old_gen_heap_size=2048"
        - name: SENTRY_DSN
          valueFrom:
            secretKeyRef:
              name: vscode-runtime-secrets
              key: sentry-dsn
        - name: MANIFEST_URL
          valueFrom:
            configMapKeyRef:
              name: vscode-runtime-config
              key: manifest-url
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
        volumeMounts:
        - name: runtime-data
          mountPath: /var/lib/vscode-runtime
        - name: runtime-logs
          mountPath: /var/log/vscode-runtime
      volumes:
      - name: runtime-data
        persistentVolumeClaim:
          claimName: vscode-runtime-data
      - name: runtime-logs
        emptyDir: {}

---
apiVersion: v1
kind: Service
metadata:
  name: vscode-runtime
  namespace: production
spec:
  selector:
    app: vscode-runtime
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: LoadBalancer

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: vscode-runtime-data
  namespace: production
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
```

#### Deploy to Kubernetes
```bash
# Create namespace
kubectl create namespace production

# Create secrets
kubectl create secret generic vscode-runtime-secrets \
  --from-literal=sentry-dsn='https://YOUR_DSN@sentry.io/PROJECT_ID' \
  -n production

# Create config
kubectl create configmap vscode-runtime-config \
  --from-literal=manifest-url='https://cdn.example.com/manifest.json' \
  -n production

# Deploy
kubectl apply -f k8s/deployment.yaml

# Check status
kubectl get pods -n production
kubectl get svc -n production

# Check logs
kubectl logs -f deployment/vscode-runtime -n production

# Check health
kubectl exec -it deployment/vscode-runtime -n production -- curl http://localhost:8080/health
```

## Configuration

### Environment Variables
```bash
# Application
DART_VM_OPTIONS="--old_gen_heap_size=2048"
LOG_LEVEL=info  # debug|info|warning|error

# Infrastructure
MANIFEST_URL=https://cdn.example.com/manifest.json
DOWNLOAD_DIR=/tmp/vscode_runtime_downloads
CACHE_TTL_HOURS=24

# Resilience
RETRY_MAX_ATTEMPTS=3
RETRY_INITIAL_DELAY_MS=1000
CIRCUIT_BREAKER_THRESHOLD=5
CIRCUIT_BREAKER_TIMEOUT_MS=60000
RATE_LIMIT_MAX_CONCURRENT=3

# Monitoring
SENTRY_DSN=https://YOUR_DSN@sentry.io/PROJECT_ID
SENTRY_ENVIRONMENT=production
SENTRY_SAMPLE_RATE=0.1

# Health checks
HEALTH_CHECK_INTERVAL_MS=30000
HEALTH_CHECK_TIMEOUT_MS=10000
```

### Configuration File
```yaml
# config/production.yaml
application:
  log_level: info
  environment: production

infrastructure:
  manifest:
    url: https://cdn.example.com/manifest.json
    cache_ttl: 24h

  download:
    directory: /tmp/vscode_runtime_downloads
    timeout: 10m
    max_concurrent: 3

  retry:
    max_attempts: 3
    initial_delay: 1s
    backoff_multiplier: 2.0

  circuit_breaker:
    failure_threshold: 5
    timeout: 60s
    half_open_timeout: 30s

  rate_limit:
    max_concurrent: 3
    min_interval: 100ms

monitoring:
  sentry:
    dsn: ${SENTRY_DSN}
    environment: production
    sample_rate: 0.1

  health:
    interval: 30s
    timeout: 10s

  metrics:
    enabled: true
    port: 9090
```

## Post-Deployment Verification

### 1. Health Check
```bash
curl http://localhost:8080/health
# Should return 200 with healthy status
```

### 2. Metrics Endpoint
```bash
curl http://localhost:8080/metrics
# Should return Prometheus metrics
```

### 3. Test Installation
```bash
curl -X POST http://localhost:8080/api/install \
  -H "Content-Type: application/json" \
  -d '{"trigger": "manual", "moduleIds": []}'
```

### 4. Monitor Logs
```bash
# Systemd
sudo journalctl -u vscode-runtime -f

# Docker
docker-compose logs -f

# Kubernetes
kubectl logs -f deployment/vscode-runtime -n production
```

### 5. Check Dashboards
- Grafana: http://grafana.example.com/d/vscode-runtime
- Sentry: https://sentry.io/organizations/yourorg/projects/vscode-runtime/

## Rollback Procedures

### Systemd
```bash
# Stop service
sudo systemctl stop vscode-runtime

# Replace binary with previous version
sudo cp /opt/vscode-runtime/bin/vscode_runtime.backup /opt/vscode-runtime/bin/vscode_runtime

# Start service
sudo systemctl start vscode-runtime
```

### Docker
```bash
# Rollback to previous image
docker-compose down
docker tag yourregistry/vscode-runtime:1.0.0 yourregistry/vscode-runtime:previous
docker-compose up -d
```

### Kubernetes
```bash
# Rollback deployment
kubectl rollout undo deployment/vscode-runtime -n production

# Or to specific revision
kubectl rollout undo deployment/vscode-runtime --to-revision=2 -n production
```

## Troubleshooting

See [Installation Failure Recovery](../runbooks/installation-failure-recovery.md) runbook.

## Related Documentation

- [Monitoring Setup](./monitoring-setup.md)
- [Health Check Guide](../runbooks/health-check-guide.md)
- [Architecture Overview](../architecture/README.md)

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-19 | Claude | Initial version |
