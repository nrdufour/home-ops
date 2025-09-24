# FluxCD to ArgoCD Migration Guide

This guide documents the migration strategy from FluxCD to ArgoCD for the home-ops cluster.

## Overview

The migration involves converting FluxCD-specific patterns to ArgoCD-compatible structures while maintaining GitOps principles and enhancing secret management.

## Key Migration Patterns

### 1. FluxCD Kustomization → ArgoCD Application

**Before (FluxCD ks.yaml):**
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: mqtt
spec:
  path: ./kubernetes/main/apps/home-automation/mqtt/app
  components:
    - ../../../../components/volsync
  targetNamespace: home-automation
  postBuild:
    substitute:
      APP: mqtt
      VOLSYNC_CAPACITY: 100Mi
```

**After (ArgoCD Application):**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: mqtt
  namespace: argocd
spec:
  project: default
  source:
    repoURL: <your-repo-url>
    path: base/apps/home-automation/mqtt
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: home-automation
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

### 2. PostBuild Variables → Kustomize Patterns

**FluxCD Variables → Kustomize Replacements:**

| FluxCD Pattern | ArgoCD/Kustomize Pattern |
|----------------|---------------------------|
| `postBuild.substitute.APP: mqtt` | `namePrefix: mqtt-` |
| `postBuild.substitute.VOLSYNC_CAPACITY: 100Mi` | `patchesStrategicMerge` with capacity patch |
| `${VARIABLE:=default}` | Use default values in base, override with patches |

### 3. Component Usage Migration

**App-specific kustomization.yaml:**
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
components:
- ../../../components/volsync
resources:
- config.yaml
- deployment.yaml
- service.yaml
patchesStrategicMerge:
- capacity-patch.yaml
namePrefix: mqtt-
namespace: home-automation
```

## Completed Migrations

### VolSync Component

✅ **Completed**: `base/components/volsync/`

**Changes Made:**
- Converted FluxCD postbuild variables to static values with defaults
- Replaced SOPS secrets with ExternalSecret + Bitwarden integration
- Separated public CA certificate into ConfigMap
- Created comprehensive README with usage examples

**Key Improvements:**
- Better secret management with External Secrets Operator
- Separation of public/private data (CA cert vs credentials)
- Standard Kustomize patterns for customization
- Enhanced documentation

## Planned Migrations

### MQTT Application

**Current Structure:**
```
kubernetes/main/apps/home-automation/mqtt/
├── ks.yaml                 # FluxCD Kustomization
└── app/
    ├── kustomization.yaml  # Basic Kustomize
    ├── config.yaml        # ConfigMap
    ├── deployment.yaml    # Deployment
    ├── service.yaml      # Service
    └── pv.yaml           # Static PV/PVC
```

**Target Structure:**
```
base/apps/home-automation/mqtt/
├── kustomization.yaml      # Main app kustomization
├── config.yaml            # ConfigMap (unchanged)
├── deployment.yaml         # Fix PVC reference
├── service.yaml           # Service (unchanged)
├── capacity-patch.yaml    # VolSync storage override
└── README.md              # Usage documentation
```

**Migration Steps:**
1. **Create base app structure**
2. **Fix PVC naming consistency** - Update deployment.yaml:
   ```yaml
   volumes:
     - name: mqtt-data
       persistentVolumeClaim:
         claimName: app  # Becomes mqtt-app with namePrefix
   ```
3. **Add capacity patch**:
   ```yaml
   # capacity-patch.yaml
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: app
   spec:
     resources:
       requests:
         storage: 100Mi
   ```
4. **Storage decision**: Remove static `pv.yaml` or keep for data migration
5. **Create ArgoCD Application**
6. **Test and validate**

## Secret Management Migration

### SOPS → ExternalSecrets

**Before:**
- SOPS-encrypted secrets in Git
- Age encryption keys managed separately
- Manual secret rotation

**After:**
- ExternalSecret resources referencing Bitwarden
- Automatic secret sync and rotation
- Public certificates in ConfigMaps

**Migration Pattern:**
1. Identify encrypted fields in SOPS files
2. Create Bitwarden items with required custom fields
3. Replace SOPS secret with ExternalSecret resource
4. Move public certificates to ConfigMaps
5. Update resource references

## General Migration Checklist

### Pre-Migration
- [ ] Backup existing data and configurations
- [ ] Set up External Secrets Operator with Bitwarden
- [ ] Test base components (e.g., VolSync) in isolated namespace
- [ ] Document current application dependencies

### Per-Application Migration
- [ ] Create base application structure
- [ ] Convert FluxCD variables to Kustomize patterns
- [ ] Update resource references (PVC names, etc.)
- [ ] Migrate secrets to ExternalSecrets
- [ ] Create ArgoCD Application manifest
- [ ] Test in non-production namespace
- [ ] Migrate data if needed
- [ ] Switch production traffic
- [ ] Remove FluxCD resources

### Post-Migration
- [ ] Verify application health
- [ ] Test backup/restore functionality (if using VolSync)
- [ ] Update monitoring and alerting
- [ ] Document any application-specific notes
- [ ] Clean up FluxCD resources

## Common Issues and Solutions

### PVC Naming Conflicts
**Problem**: FluxCD `${APP}` variable vs Kustomize `namePrefix`
**Solution**: Update resource references to use consistent naming pattern

### Storage Management
**Problem**: Static PVs vs VolSync-managed storage
**Solutions**:
- Migrate data during maintenance window
- Use VolSync for backups while keeping static PV
- Gradual migration approach

### Secret References
**Problem**: SOPS-encrypted secrets no longer available
**Solution**: Ensure ExternalSecrets are syncing before removing SOPS

### Component Dependencies
**Problem**: Component references in FluxCD paths
**Solution**: Update to relative base component paths in Kustomize

## Best Practices

### Directory Structure
```
base/
├── components/           # Reusable components
│   └── volsync/         # VolSync backup component
├── apps/                # Application definitions
│   └── home-automation/ # Grouped by domain
│       └── mqtt/        # Individual applications
└── overlays/            # Environment-specific overrides (if needed)
```

### Naming Conventions
- Use consistent `namePrefix` for related resources
- Match ArgoCD Application names to directory structure
- Use descriptive patch file names (`capacity-patch.yaml`, `env-patch.yaml`)

### Secret Management
- Store only sensitive data in Bitwarden
- Use ConfigMaps for public certificates and configuration
- Group related secrets in single Bitwarden items
- Use meaningful property names in Bitwarden fields

## Resources

- [VolSync Component README](../base/components/volsync/README.md)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kustomize Documentation](https://kustomize.io/)
- [External Secrets Operator](https://external-secrets.io/)

## Migration Status

| Application | Status | Notes |
|-------------|--------|-------|
| VolSync Component | ✅ Complete | Base component ready for use |
| MQTT | 📋 Planned | Simple app, good first migration |
| Home Assistant | 📋 Planned | More complex, has SOPS secrets |
| Other Apps | 📋 To assess | Need individual evaluation |

---

*Last Updated: $(date)*
*Migration Guide Version: 1.0*