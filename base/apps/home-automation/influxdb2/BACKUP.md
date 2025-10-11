# InfluxDB2 Backup Guide

This document describes the native InfluxDB backup solution for the home-automation cluster.

## Overview

The backup system uses:
- **CronJob**: Runs daily at 2 AM to create backups
- **Native InfluxDB backup**: Uses `influx backup` command for application-consistent backups
- **Longhorn storage**: 50Gi PVC for storing backup files
- **Bitwarden**: Admin token stored in ExternalSecret

## Backup Configuration

| Setting | Value |
|---------|-------|
| Schedule | Daily at 2:00 AM |
| Retention | 7 days |
| Storage | 50Gi Longhorn PVC |
| Backup Location | `/backup/influxdb-backup-YYYYMMDD-HHMMSS` |
| Service Endpoint | `http://influxdb2:8086` |

## Manual Backup

To trigger a backup manually:

```bash
# Create a one-time job from the CronJob
kubectl create job --from=cronjob/influxdb2-backup influxdb2-backup-manual -n home-automation

# Watch the job progress
kubectl logs -f job/influxdb2-backup-manual -n home-automation

# Check backup status
kubectl get jobs -n home-automation | grep influxdb2-backup
```

## View Available Backups

List all available backups:

```bash
# Get the backup pod name (use any running influxdb2 pod or backup job pod)
kubectl get pods -n home-automation | grep influxdb2

# List backups
kubectl exec -it deployment/influxdb2 -n home-automation -- ls -lh /backup/

# Or from a backup job pod
kubectl exec -it job/influxdb2-backup-manual -n home-automation -- ls -lh /backup/

# Check backup size
kubectl exec -it deployment/influxdb2 -n home-automation -- du -sh /backup/*
```

## Restore from Backup

### Option 1: Restore to Running Instance

Restore to the current running InfluxDB instance:

```bash
# List available backups
kubectl exec -it deployment/influxdb2 -n home-automation -- ls -lh /backup/

# Restore from specific backup (replace timestamp)
kubectl exec -it deployment/influxdb2 -n home-automation -- \
  influx restore \
    --host http://localhost:8086 \
    --token "${INFLUXDB_TOKEN}" \
    /backup/influxdb-backup-20250111-020000
```

### Option 2: Restore to New Instance

For disaster recovery, restore to a fresh InfluxDB instance:

```bash
# 1. Scale down current deployment
kubectl scale deployment/influxdb2 --replicas=0 -n home-automation

# 2. Delete the data PVC (WARNING: destructive!)
kubectl delete pvc influxdb2-pvc -n home-automation

# 3. Recreate the PVC (ArgoCD will do this automatically)
# Wait for PVC to be bound

# 4. Create a temporary pod with both volumes mounted
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: influxdb2-restore
  namespace: home-automation
spec:
  containers:
  - name: restore
    image: influxdb:2.7
    command: ["/bin/sh", "-c", "sleep 3600"]
    volumeMounts:
    - name: data
      mountPath: /var/lib/influxdb2
    - name: backup
      mountPath: /backup
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: influxdb2-pvc
  - name: backup
    persistentVolumeClaim:
      claimName: influxdb2-backup-pvc
EOF

# 5. Restore from backup
kubectl exec -it influxdb2-restore -n home-automation -- \
  influx restore /backup/influxdb-backup-20250111-020000 \
    --new-bucket rtl433_sensors \
    --new-org homelab

# 6. Clean up restore pod
kubectl delete pod influxdb2-restore -n home-automation

# 7. Scale deployment back up
kubectl scale deployment/influxdb2 --replicas=1 -n home-automation
```

## Monitoring Backups

### Check CronJob Status

```bash
# View CronJob configuration
kubectl get cronjob influxdb2-backup -n home-automation

# View recent job runs
kubectl get jobs -n home-automation | grep influxdb2-backup

# View job history
kubectl describe cronjob influxdb2-backup -n home-automation
```

### Check Backup Logs

```bash
# Get logs from latest backup job
kubectl logs -l app=influxdb2-backup -n home-automation --tail=100

# Get logs from specific job
kubectl logs job/influxdb2-backup-28956480 -n home-automation
```

### Check ExternalSecret Status

```bash
# Verify the admin token secret is syncing
kubectl get externalsecret influxdb2-admin-token -n home-automation
kubectl describe externalsecret influxdb2-admin-token -n home-automation

# View the created secret (token will be base64 encoded)
kubectl get secret influxdb2-admin-token -n home-automation -o yaml
```

## Troubleshooting

### Backup Job Fails

1. **Check CronJob logs:**
   ```bash
   kubectl logs -l app=influxdb2-backup -n home-automation
   ```

2. **Common issues:**
   - Invalid token: Verify Bitwarden item has `INFLUXDB2_TOKEN` field
   - PVC not bound: Check `kubectl get pvc -n home-automation`
   - Network connectivity: Verify service `http://influxdb2:8086` is accessible

3. **Test connectivity manually:**
   ```bash
   kubectl run -it --rm debug --image=influxdb:2.7 --restart=Never -n home-automation -- \
     influx ping --host http://influxdb2:8086
   ```

### Backup PVC Full

Check available space:

```bash
kubectl exec -it deployment/influxdb2 -n home-automation -- df -h /backup
```

If full, either:
- Increase PVC size in `backup-pvc.yaml`
- Reduce retention in `backup-cronjob.yaml` (change `-mtime +7` to fewer days)
- Manually delete old backups

### Restore Fails

1. **Check backup integrity:**
   ```bash
   kubectl exec -it deployment/influxdb2 -n home-automation -- \
     ls -lR /backup/influxdb-backup-20250111-020000/
   ```

2. **Verify token is correct:**
   ```bash
   kubectl get secret influxdb2-admin-token -n home-automation -o jsonpath='{.data.token}' | base64 -d
   ```

3. **Check InfluxDB logs:**
   ```bash
   kubectl logs deployment/influxdb2 -n home-automation
   ```

## Configuration Changes

### Change Backup Schedule

Edit `backup-cronjob.yaml`:

```yaml
spec:
  # Run every 6 hours
  schedule: "0 */6 * * *"

  # Run daily at midnight
  schedule: "0 0 * * *"

  # Run hourly
  schedule: "0 * * * *"
```

### Change Retention Period

Edit the cleanup command in `backup-cronjob.yaml`:

```bash
# Keep 14 days instead of 7
find /backup -maxdepth 1 -name "influxdb-backup-*" -type d -mtime +14 -exec rm -rf {} \;
```

### Increase Backup Storage

Edit `backup-pvc.yaml`:

```yaml
spec:
  resources:
    requests:
      storage: 100Gi  # Increase from 50Gi
```

Then expand the PVC:

```bash
kubectl edit pvc influxdb2-backup-pvc -n home-automation
# (Longhorn supports online expansion)
```

## Future Improvements

### Add VolSync for Offsite Backups

To send backups to S3/Restic repository, add the VolSync component:

1. Create `backup-volsync/` directory
2. Add VolSync ReplicationSource for `influxdb2-backup-pvc`
3. Configure Restic repository in Bitwarden
4. This provides offsite backup protection

### Migrate InfluxDB to Longhorn

Currently InfluxDB data lives on NFS storage, which has risks for databases:
- Consider migrating to Longhorn for better performance and safety
- See main documentation for migration steps

### Add Monitoring/Alerts

Set up alerts for:
- Backup job failures
- Backup storage approaching full
- Backup age (if last backup is too old)

Use Prometheus/Grafana or similar monitoring solution.

## Backup Schedule

The backup runs daily at 2:00 AM with the following process:

1. Create timestamped directory: `/backup/influxdb-backup-YYYYMMDD-HHMMSS`
2. Run `influx backup` to create consistent snapshot
3. Delete backups older than 7 days
4. Show backup size and available backups

## Security Notes

- Admin token stored securely in Bitwarden
- Token synced via ExternalSecret Operator
- Backup PVC uses Longhorn (encrypted at rest if configured)
- Access to backup data requires cluster access
- Consider encrypting backups before sending offsite
