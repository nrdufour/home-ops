# VolSync Component

This component provides volume synchronization and backup capabilities using [VolSync](https://volsync.readthedocs.io/) with Restic backend.

## Overview

The component creates:
- **ReplicationSource**: Handles backup/sync from a source PVC
- **ReplicationDestination**: Handles restore operations
- **PersistentVolumeClaim**: Target PVC that gets restored data
- **ExternalSecret**: Pulls credentials from Bitwarden
- **ConfigMap**: Contains public CA certificate

## Prerequisites

1. **External Secrets Operator** installed with `bitwarden-fields` ClusterSecretStore
2. **VolSync operator** installed in the cluster
3. **Longhorn** storage class (or customize storage settings)

## Bitwarden Setup

Create a Bitwarden item with a unique name (the UUID will be used in the component) containing these custom fields:
- `RESTIC_REPOSITORY`: S3/Restic repository URL
- `RESTIC_PASSWORD`: Repository encryption password
- `AWS_ACCESS_KEY_ID`: S3 access key
- `AWS_SECRET_ACCESS_KEY`: S3 secret key

## CA Certificate Setup

Update `local/ca-configmap.yaml` with your actual public CA certificate:

```yaml
data:
  ca.crt: |
    -----BEGIN CERTIFICATE-----
    MIIFXzCCA0egAwIBAgIJALK1ihrXh...
    -----END CERTIFICATE-----
```

## Usage

### Basic Usage

In your application's kustomization.yaml:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- app-config.yaml
components:
- ../../../base/components/volsync
replacements:
# Replace resource names with app name
- source:
    kind: ConfigMap
    name: app-config
    fieldPath: metadata.name
  targets:
  - select:
      kind: PersistentVolumeClaim
    fieldPaths:
    - metadata.name
  - select:
      kind: ReplicationSource
    fieldPaths:
    - metadata.name
    - spec.sourcePVC
  - select:
      kind: ReplicationDestination
    fieldPaths:
    - metadata.name
  - select:
      kind: ExternalSecret
    fieldPaths:
    - metadata.name
    - spec.target.name
  - select:
      kind: ConfigMap
      name: app-volsync-ca
    fieldPaths:
    - metadata.name
# Replace Bitwarden key reference (removes app- prefix)
- source:
    kind: ConfigMap
    name: app-config
    fieldPath: data.BITWARDEN_KEY
  targets:
  - select:
      kind: ExternalSecret
    fieldPaths:
    - spec.data.[*].remoteRef.key
    options:
      delimiter: '-'
      index: 1
# Replace storage class
- source:
    kind: ConfigMap
    name: app-config
    fieldPath: data.STORAGE_CLASS
  targets:
  - select:
      kind: PersistentVolumeClaim
    fieldPaths:
    - spec.storageClassName
  - select:
      kind: ReplicationSource
    fieldPaths:
    - spec.restic.storageClassName
  - select:
      kind: ReplicationDestination
    fieldPaths:
    - spec.restic.storageClassName
# Replace storage capacity
- source:
    kind: ConfigMap
    name: app-config
    fieldPath: data.STORAGE_CAPACITY
  targets:
  - select:
      kind: PersistentVolumeClaim
    fieldPaths:
    - spec.resources.requests.storage
  - select:
      kind: ReplicationDestination
    fieldPaths:
    - spec.restic.capacity
# Replace cache capacity
- source:
    kind: ConfigMap
    name: app-config
    fieldPath: data.CACHE_CAPACITY
  targets:
  - select:
      kind: ReplicationSource
    fieldPaths:
    - spec.restic.cacheCapacity
  - select:
      kind: ReplicationDestination
    fieldPaths:
    - spec.restic.cacheCapacity
# Replace backup schedule
- source:
    kind: ConfigMap
    name: app-config
    fieldPath: data.BACKUP_SCHEDULE
  targets:
  - select:
      kind: ReplicationSource
    fieldPaths:
    - spec.trigger.schedule
namePrefix: myapp-
```

The required `app-config.yaml` ConfigMap should contain all configurable values:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  # Required: Bitwarden item UUID for credentials
  BITWARDEN_KEY: "your-bitwarden-item-uuid-here"
  # Optional: Storage settings (defaults shown)
  STORAGE_CLASS: "longhorn"
  STORAGE_CAPACITY: "5Gi"
  CACHE_CAPACITY: "2Gi"
  # Optional: Backup schedule (default: hourly)
  BACKUP_SCHEDULE: "0 * * * *"
```

### Customization with Patches

For custom storage requirements:

```yaml
# capacity-patch.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app
spec:
  resources:
    requests:
      storage: "20Gi"
```

```yaml
# kustomization.yaml
components:
- ../../../base/components/volsync
patchesStrategicMerge:
- capacity-patch.yaml
namePrefix: myapp-
```

### Advanced Configuration

Create overlays for different apps:

```yaml
# base/overlays/volsync-plex/kustomization.yaml
components:
- ../../components/volsync
patchesStrategicMerge:
- storage-patch.yaml
- schedule-patch.yaml
namePrefix: plex-
```

## Default Configuration

| Setting | Default Value | Description |
|---------|---------------|-------------|
| Storage Class | `longhorn` | Default storage class |
| Access Mode | `ReadWriteOnce` | PVC access mode |
| Capacity | `5Gi` | Default storage size |
| Snapshot Class | `longhorn-snapshot-vsc` | Volume snapshot class |
| Cache Capacity | `2Gi` | Restic cache size |
| Copy Method | `Snapshot` | Backup method |
| Schedule | `0 * * * *` | Hourly backups |
| User/Group ID | `1000` | Security context |
| Retention | 24 hourly, 7 daily | Backup retention |

## Operations

### Trigger Manual Restore

To restore from backup:

```bash
kubectl patch replicationdestination myapp-dst --type='merge' -p='{"spec":{"trigger":{"manual":"restore-$(date +%s)"}}}'
```

### Monitor Backup Status

```bash
kubectl get replicationsource myapp -o yaml
kubectl get replicationdestination myapp-dst -o yaml
```

### Check External Secret Status

```bash
kubectl get externalsecret myapp-volsync-secret
kubectl describe externalsecret myapp-volsync-secret
```

## Troubleshooting

### Common Issues

1. **ExternalSecret not syncing**
   - Verify Bitwarden item exists with correct field names
   - Check ClusterSecretStore `bitwarden-fields` is healthy

2. **CA certificate errors**
   - Ensure `ca-configmap.yaml` contains valid certificate
   - Verify certificate matches your S3/Restic backend

3. **Storage class not found**
   - Customize storage class in patches if not using Longhorn

4. **Permission issues**
   - Adjust `VOLSYNC_PUID`/`VOLSYNC_PGID` in patches if needed

### Debugging Commands

```bash
# Check VolSync operator logs
kubectl logs -n volsync-system deployment/volsync

# Check external secret status
kubectl get externalsecret -A

# View backup job logs
kubectl logs job/volsync-src-<hash>
```

## Migration from FluxCD

This component replaces FluxCD postbuild variables with Kustomize replacements:

- Use `namePrefix` instead of `${APP}` variable
- Use `patchesStrategicMerge` for customization instead of variables with defaults
- Sensitive data moved to ExternalSecret/Bitwarden instead of SOPS

## Security Notes

- Only store sensitive credentials in Bitwarden
- Public CA certificates are stored in ConfigMaps (not encrypted)
- Repository passwords and AWS keys remain encrypted in transit and at rest
- Regular rotation of Restic repository passwords recommended