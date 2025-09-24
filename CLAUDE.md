# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a home operations (home-ops) repository for managing Kubernetes infrastructure at home using GitOps practices. The repository is currently in migration from Flux to ArgoCD, which explains the dual directory structure.

## Key Commands

### Task Management
- `task --list` - List all available tasks
- `task k8s:bootstrap` - Bootstrap Flux on a cluster (installs Prometheus Operator CRDs, Flux, GitOps access, and kustomizations)
- `task sops:update` - Update all SOPS secrets by running `sops updatekeys` on all `*.sops.yaml` files

### SOPS and Secrets
- SOPS configuration is in `.sops.yaml` with Age encryption
- Age key file location: `~/.config/sops/age/keys.txt` (set via `SOPS_AGE_KEY_FILE` env var)
- Decrypt secrets: `sops --decrypt <file>.sops.yaml`
- Edit encrypted secrets: `sops <file>.sops.yaml`

### Kubectl Context
- Default kubeconfig: `kubernetes/kubernetes/main/kubeconfig`
- Main cluster context: `main`

### YAML Linting
- Uses yamllint with configuration in `.yamllint`
- Run: `yamllint .`
- Ignores `*.sops.yml` and `*.sops.yaml` files

## Architecture

### Migration Status: Flux → ArgoCD

The repository is in active migration from Flux to ArgoCD, resulting in two parallel directory structures:

**Legacy (Flux - being phased out):**
- `kubernetes/main/` - Flux-managed cluster configuration

**Current (ArgoCD - target state):**
- `base/` - ArgoCD application definitions and reusable Kustomize bases
- `clusters/` - Cluster-specific ArgoCD configurations

### Directory Structure

**ArgoCD Structure (Current):**
- **`base/`** - ArgoCD application definitions and reusable Kustomize bases
  - `apps/` - Application deployments (cnpg-system, home-automation, self-hosted, etc.)
  - `argocd/` - ArgoCD configuration
  - `infra/` - Infrastructure components (cert-manager, networking, security, system, observability)
  - `components/` - Shared Kustomize components (volsync, etc.)

- **`clusters/`** - Cluster-specific configurations
  - `main/` - Main cluster ArgoCD applications

- **`docs/`** - Documentation and migration guides
  - `fluxcd-to-argocd-migration.md` - Comprehensive migration guide

**Flux Structure (Legacy):**
- **`kubernetes/main/`** - Main cluster configuration using Flux
  - `apps/` - Application namespaces (ai, flux-system, home-automation, media, self-hosted)
  - `bootstrap/flux/` - Flux bootstrap configuration
  - `flux/` - Flux system configuration (config, repositories, vars)
  - `components/` - Shared components for the main cluster

**Archived:**
- **`bin/`** - Contains legacy scripts that are no longer in use and should be archived

### GitOps Pattern

During migration:
- **ArgoCD** is the target GitOps solution managing applications defined in `base/` and `clusters/`
- **Flux** is legacy but still managing some resources in `kubernetes/main/`

### Key Infrastructure Components

Infrastructure is organized by category in `base/infra/`:
- **cert-manager** - TLS certificate management
- **network** - Ingress (nginx), external-dns, CoreDNS
- **security** - External secrets, Bitwarden store, Kyverno policies
- **system** - Node feature discovery, Kured, OpenEBS, VolSync, snapshot controller
- **observability** - Prometheus stack
- **longhorn-system** - Longhorn storage

### Secrets Management

- **Legacy**: SOPS with Age encryption for sensitive data in `kubernetes/main/`
- **Current**: External Secrets Operator with Bitwarden integration
- Encrypted files follow pattern `*.sops.yaml`
- ExternalSecret resources pull from `bitwarden-fields` ClusterSecretStore
- Public certificates stored in ConfigMaps (not encrypted)
- Bootstrap secrets include GitOps access and SOPS keys
- All secrets are automatically ignored by Renovate

### Dependency Management

- **Renovate** handles automated dependency updates
- Configuration in `renovate.json5` with custom rules for specific applications
- Manages ArgoCD, Flux, Helm values, Kubernetes manifests, and Docker images
- Automerges minor and patch updates for stable versions

### Component Management

**Reusable Kustomize Components** in `base/components/`:
- **volsync** - Volume backup and sync with Restic backend
  - Uses ExternalSecret for credentials from Bitwarden
  - ConfigMap for public CA certificates
  - Supports customization via patches and namePrefix
  - See `base/components/volsync/README.md` for usage

**Component Usage Pattern:**
```yaml
# In application kustomization.yaml
components:
- ../../../components/volsync
patchesStrategicMerge:
- capacity-patch.yaml
namePrefix: myapp-
```

## Development Workflow

1. Make changes to YAML configurations (prefer `base/` and `clusters/` for new work)
2. Validate with yamllint: `yamllint .`
3. For encrypted secrets, use `sops` to edit: `sops <file>.sops.yaml`
4. For ExternalSecrets, update Bitwarden vault with required fields
5. Commit changes - ArgoCD will automatically sync
6. For Flux bootstrap (legacy): `task k8s:bootstrap`
7. Update SOPS keys when needed: `task sops:update`

## Environment Setup

Required environment variables (set in Taskfile.yaml):
- `KUBECONFIG` - Path to kubectl configuration
- `SOPS_AGE_KEY_FILE` - Path to Age private key for SOPS

The repository uses Nix for development environment setup (`default.nix`, `.envrc`).