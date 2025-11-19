# Runbook: Installation Failure Recovery

## Overview
This runbook provides step-by-step procedures for recovering from VS Code Runtime installation failures.

## Severity Levels
- **P1 (Critical)**: Complete installation failure, system unusable
- **P2 (High)**: Partial installation, critical modules missing
- **P3 (Medium)**: Optional modules missing, system usable
- **P4 (Low)**: Minor issues, cosmetic problems

## Common Scenarios

### Scenario 1: Network Timeout During Download

**Symptoms:**
- Error: "Download failed: Connection timeout"
- Circuit breaker may be open
- Retry attempts exhausted

**Diagnosis:**
```bash
# Check network connectivity
curl -I https://cdn.example.com/manifest.json

# Check circuit breaker status
# Via health check endpoint:
curl http://localhost:8080/health
```

**Resolution:**

1. **Verify Network Connectivity**
   ```bash
   ping cdn.example.com
   traceroute cdn.example.com
   ```

2. **Check Circuit Breaker Status**
   - If open, wait for cooldown period (60s for downloads)
   - Or manually reset via health check API

3. **Retry Installation**
   ```dart
   // Automatic retry after circuit breaker closes
   // Or trigger manual retry:
   await installRuntimeCommand.handle(command);
   ```

4. **If Persistent**:
   - Check proxy settings
   - Verify firewall rules
   - Check CDN status
   - Switch to mirror URL if available

**Prevention:**
- Monitor network stability
- Configure longer timeouts for slow connections
- Set up CDN mirrors

---

### Scenario 2: Disk Space Exhausted

**Symptoms:**
- Error: "File system error: No space left on device"
- Installation fails during extraction
- Partial files in download directory

**Diagnosis:**
```bash
# Check disk space
df -h /tmp/vscode_runtime_downloads

# Check download directory size
du -sh /tmp/vscode_runtime_downloads
```

**Resolution:**

1. **Clean Up Downloads**
   ```bash
   # Remove partial downloads
   rm -rf /tmp/vscode_runtime_downloads/*

   # Or via API:
   await fileSystemService.cleanupDownloads();
   ```

2. **Verify Space Requirements**
   ```bash
   # Minimum required: 1GB
   # Recommended: 2GB+ for comfortable installation
   ```

3. **Free Up Space**
   - Remove old installations
   - Clear system cache
   - Move download directory to larger partition

4. **Retry Installation**
   ```dart
   await installRuntimeCommand.handle(command);
   ```

**Prevention:**
- Monitor disk space proactively
- Set alerts at 80% capacity
- Implement automatic cleanup of old downloads

---

### Scenario 3: Checksum Verification Failed

**Symptoms:**
- Error: "Verification failed: Checksum mismatch"
- Downloaded file corrupted
- SHA256 hash doesn't match manifest

**Diagnosis:**
```bash
# Manual verification
sha256sum /tmp/vscode_runtime_downloads/module.zip

# Compare with manifest
cat manifest.json | jq '.modules[] | select(.id=="module") | .artifacts[0].checksum'
```

**Resolution:**

1. **Delete Corrupted File**
   ```bash
   rm /tmp/vscode_runtime_downloads/module.zip
   ```

2. **Clear Cache**
   ```dart
   await cacheService.remove('runtime_manifest');
   await manifestRepository.clearCache();
   ```

3. **Retry Download**
   ```dart
   await installRuntimeCommand.handle(command);
   ```

4. **If Persistent**:
   - Check for MITM proxy interference
   - Verify CDN integrity
   - Switch to alternative download URL
   - Contact support with error details

**Prevention:**
- Implement certificate pinning
- Monitor CDN for corruption
- Set up integrity monitoring

---

### Scenario 4: Dependency Resolution Failed

**Symptoms:**
- Error: "Dependency exception: Circular dependency detected"
- Error: "Dependency exception: Module X requires Y, but Y not found"
- Installation stuck at dependency resolution

**Diagnosis:**
```bash
# Check module dependencies
cat manifest.json | jq '.modules[] | {id, dependencies}'

# Verify circular dependencies
# (requires custom script or manual inspection)
```

**Resolution:**

1. **Fetch Latest Manifest**
   ```dart
   await manifestRepository.clearCache();
   await manifestRepository.fetchManifest();
   ```

2. **Install Required Dependencies First**
   ```dart
   // Install in correct order:
   await installRuntimeCommand.handle(
     InstallRuntimeCommand(
       moduleIds: [ModuleId('base'), ModuleId('core')],
       trigger: InstallationTrigger.manual,
     ),
   );
   ```

3. **If Circular Dependency**:
   - Report to development team
   - Manifest needs fixing
   - Temporarily exclude problematic module

**Prevention:**
- Validate manifest before publishing
- Automated circular dependency detection
- Dependency resolution unit tests

---

### Scenario 5: Installation Cancelled by User

**Symptoms:**
- Status: "Installation cancelled"
- Partial modules installed
- State inconsistent

**Diagnosis:**
```bash
# Check installation status
curl http://localhost:8080/api/runtime/status

# Check installed modules
ls -la /opt/vscode_runtime/
```

**Resolution:**

1. **Check Current State**
   ```dart
   final statusDto = await getRuntimeStatusQueryHandler.handle(query);

   if (statusDto.isPartiallyInstalled) {
     // Partially installed, can resume
   }
   ```

2. **Resume or Restart**
   ```dart
   // Option 1: Resume installation
   await installRuntimeCommand.handle(
     InstallRuntimeCommand(
       moduleIds: statusDto.missingModules,
       trigger: InstallationTrigger.manual,
     ),
   );

   // Option 2: Start fresh
   await uninstallRuntimeCommand.handle(UninstallRuntimeCommand());
   await installRuntimeCommand.handle(InstallRuntimeCommand());
   ```

3. **Clean Up Temporary Files**
   ```bash
   rm -rf /tmp/vscode_runtime_downloads/*
   ```

**Prevention:**
- Implement atomic installations where possible
- Persist installation progress
- Support resumable installations

---

## Escalation Path

### Level 1: Automated Recovery
- Automatic retries (3 attempts with exponential backoff)
- Circuit breaker automatic recovery
- Cache invalidation and refetch

### Level 2: User Self-Service
- Clear instructions in error messages
- Runbook links in documentation
- Health check API for diagnostics

### Level 3: Support Team
- Contact: support@example.com
- SLA: 4 hours for P1, 24 hours for P2
- Provide: logs, health check output, error details

### Level 4: Engineering Team
- Contact: engineering@example.com
- SLA: Same day for P1, 3 days for P2
- Required for: manifest issues, CDN problems, architecture bugs

---

## Monitoring & Alerts

### Key Metrics to Monitor

1. **Installation Success Rate**
   - Target: > 95%
   - Alert: < 90%

2. **Average Installation Time**
   - Target: < 5 minutes
   - Alert: > 10 minutes

3. **Network Timeout Rate**
   - Target: < 2%
   - Alert: > 5%

4. **Checksum Verification Failures**
   - Target: < 0.1%
   - Alert: > 1%

5. **Circuit Breaker Open Rate**
   - Target: < 1% of requests
   - Alert: > 5% of requests

### Log Locations

```
# Application logs
/var/log/vscode_runtime/application.log

# Infrastructure logs
/var/log/vscode_runtime/infrastructure.log

# Download logs
/var/log/vscode_runtime/downloads.log

# Error tracking (Sentry)
https://sentry.io/organizations/yourorg/issues/
```

---

## Post-Incident Review

After resolving any P1 or P2 incident:

1. Document the incident
2. Identify root cause
3. Implement preventive measures
4. Update runbook if needed
5. Share learnings with team

## Related Runbooks

- [Network Issues Troubleshooting](./network-troubleshooting.md)
- [Cache Management](./cache-management.md)
- [Health Check Guide](./health-check-guide.md)
- [Rollback Procedures](./rollback-procedures.md)

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-19 | Claude | Initial version |
