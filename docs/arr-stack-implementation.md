# *arr Stack Implementation Guide

## Overview
This document tracks the implementation of a complete media automation stack on the Kubernetes cluster using ArgoCD, with privacy protection via ProtonVPN.

**Branch:** `arr-stack`
**Target Directory:** `base/apps/media/`
**Status:** In Progress
**Started:** 2025-10-13

## Architecture

### Components

1. **qBittorrent** - Torrent client with Gluetun VPN sidecar
   - All torrent traffic routed through ProtonVPN
   - Kill switch enabled (traffic blocked if VPN drops)
   - Web UI: `http://qbittorrent.internal`

2. **Prowlarr** - Indexer manager
   - Centralized indexer/tracker management
   - Integrates with Sonarr, Radarr
   - Web UI: `http://prowlarr.internal`

3. **Sonarr** - TV show management
   - Automated TV show downloads
   - Episode tracking and upgrading
   - Web UI: `http://sonarr.internal`

4. **Radarr** - Movie management
   - Automated movie downloads
   - Quality management and upgrading
   - Web UI: `http://radarr.internal`

5. **NZBGet** - Usenet downloader
   - Fast, efficient NZB/Usenet downloads
   - Lightweight C++ implementation
   - Complements torrent sources
   - Web UI: `http://nzbget.internal`

6. **Future additions:**
   - **FlareSolverr** (Cloudflare bypass proxy) - Enables Prowlarr to use Cloudflare-protected indexers (1337x, etc.)
   - Bazarr (subtitles)
   - Lidarr (music)
   - Readarr (books/audiobooks)

### Infrastructure

#### Storage Strategy

**Config Storage:** Longhorn (ReadWriteOnce) with VolSync backups
- Each app gets its own PVC for configuration
- Automated backups to Restic via VolSync component
- Storage class: `longhorn`

**Media Storage:** NFS mount from cardinal.internal
- Server: `cardinal.internal`
- Export: `/tank/Media` (10.0.0.0/8)
- Export: `/tank/Books` (10.0.0.0/8)

#### NFS Directory Structure on cardinal.internal

**Current structure under `/tank/Media`:**
```
/tank/Media/
├── Documentaries/          # Jellyfin: Movies type
├── Home Videos/            # Jellyfin: Home Videos and Photos
├── Movies/                 # Jellyfin: Movies type
├── Movies-to-sort/         # Not managed by Jellyfin
├── Music/                  # Managed by Navidrome
├── Music-to-sort/          # Not managed by Jellyfin
├── Music Videos/           # Jellyfin: Music Video type
├── Performances/           # Jellyfin: Movies type
├── Pictures/               # Not managed by Jellyfin
├── Samples/                # Not managed by Jellyfin
├── Series/                 # Jellyfin: Shows type
└── Youtube/                # Not managed by Jellyfin
```

**New directories to be created for *arr stack:**
```
/tank/Media/
└── torrents/               # qBittorrent download directory
    ├── incomplete/         # Active downloads
    ├── complete/           # Completed downloads (seeding)
    └── watch/              # Watch folder for .torrent files (optional)
```

**Mount strategy:**
- **qBittorrent:** Mount `/tank/Media/torrents` for downloads
- **NZBGet:** Mount `/tank/Media/torrents` for downloads (shared directory, no collision)
- **Sonarr:** Mount `/tank/Media/Series` (TV shows) + `/tank/Media/torrents` (downloads)
- **Radarr:** Mount `/tank/Media/Movies` (movies) + `/tank/Media/torrents` (downloads)
- **Prowlarr:** No media mounts needed (only manages indexers)

#### Networking

- **Ingress:** nginx-internal
- **TLS:** cert-manager with ca-server-cluster-issuer
- **Domain:** `*.internal` (NOT `*.home.internal`)
- **Access Control:** Whitelisted to `10.0.0.0/8`
- **VPN:** ProtonVPN via Gluetun sidecar

#### VPN Configuration (Gluetun + ProtonVPN)

- **Provider:** ProtonVPN
- **Implementation:** Gluetun sidecar container in qBittorrent pod
- **Features:**
  - OpenVPN or Wireguard support
  - Kill switch (blocks all traffic if VPN fails)
  - Port forwarding support
  - Health checks
- **Reference:** onedr0p/home-ops (FluxCD-based, but no VPN details)

#### Secrets Management

- **Method:** External Secrets Operator with Bitwarden
- **Store:** `bitwarden-fields` ClusterSecretStore
- **Pattern:** ExternalSecret resources pull from Bitwarden vault

#### Namespace Management

- **Important:** Namespace is NOT managed in manifests
- Namespace: `media`
- ArgoCD creates namespace automatically via `CreateNamespace=true` syncOption
- No `namespace.yaml` file in the app directories

## Implementation Checklist

### Phase 1: Foundation & Documentation (Session 1)
- [x] Create project documentation
- [x] Create `base/apps/media/` directory structure
- [x] Identify NFS exports on cardinal.internal
- [x] Document existing `/tank/Media` directory structure
- [ ] Create Bitwarden item for Media stack secrets
- [ ] Create `/tank/Media/torrents` directory structure on cardinal.internal

### Phase 2: qBittorrent + VPN (Session 1-2)
- [ ] Create qBittorrent base directory structure
- [ ] Create ExternalSecret for ProtonVPN credentials
- [ ] Create ExternalSecret for qBittorrent web UI credentials
- [ ] Create qBittorrent HelmRelease with Gluetun sidecar
  - [ ] Configure Gluetun for ProtonVPN
  - [ ] Configure kill switch
  - [ ] Set up port forwarding (if needed)
- [ ] Create PVC for qBittorrent config (Longhorn)
- [ ] Configure NFS mount for torrents directory
- [ ] Add VolSync component for config backups
- [ ] Create kustomization.yaml
- [ ] Create ArgoCD Application manifest
- [ ] Test VPN connection and kill switch
- [ ] Verify torrent functionality

### Phase 3: Prowlarr (Session 2)
- [ ] Create Prowlarr base directory structure
- [ ] Create Prowlarr HelmRelease
- [ ] Create PVC for Prowlarr config
- [ ] Add VolSync component
- [ ] Create ingress manifest
- [ ] Create kustomization.yaml
- [ ] Create ArgoCD Application manifest
- [ ] Configure indexers
- [ ] Test connectivity

### Phase 4: Sonarr (Session 2-3)
- [ ] Create Sonarr base directory structure
- [ ] Create Sonarr HelmRelease
- [ ] Create PVC for Sonarr config
- [ ] Add VolSync component
- [ ] Configure NFS mounts (torrents, Series)
- [ ] Create ingress manifest
- [ ] Create kustomization.yaml
- [ ] Create ArgoCD Application manifest
- [ ] Link to Prowlarr and qBittorrent
- [ ] Test download flow

### Phase 5: Radarr (Session 3)
- [ ] Create Radarr base directory structure
- [ ] Create Radarr HelmRelease
- [ ] Create PVC for Radarr config
- [ ] Add VolSync component
- [ ] Configure NFS mounts (torrents, Movies)
- [ ] Create ingress manifest
- [ ] Create kustomization.yaml
- [ ] Create ArgoCD Application manifest
- [ ] Link to Prowlarr and qBittorrent
- [ ] Test download flow

### Phase 6: ArgoCD Integration (Session 3-4)
- [ ] Update `base/apps/kustomization.yaml` to include media apps
- [ ] Update `clusters/main/` if needed
- [ ] Test GitOps sync for all apps
- [ ] Verify automated sync and self-heal

### Phase 7: Testing & Documentation (Session 4)
- [ ] End-to-end testing
- [ ] Document configuration steps
- [ ] Create troubleshooting guide
- [ ] Update CLAUDE.md if needed

## Directory Structure

```
base/apps/media/
├── kustomization.yaml                    # Main kustomization for media namespace
├── qbittorrent/
│   ├── kustomization.yaml
│   ├── helm-release.yaml                 # HelmRelease with Gluetun sidecar
│   ├── pvc.yaml                          # Config storage (Longhorn)
│   ├── vpn-secret.yaml                   # ExternalSecret for ProtonVPN
│   ├── app-secret.yaml                   # ExternalSecret for qBittorrent creds
│   ├── ingress.yaml                      # Ingress for web UI
│   └── volsync/
│       └── (VolSync component patches)
├── prowlarr/
│   ├── kustomization.yaml
│   ├── helm-release.yaml
│   ├── pvc.yaml
│   ├── ingress.yaml
│   └── volsync/
├── sonarr/
│   ├── kustomization.yaml
│   ├── helm-release.yaml
│   ├── pvc.yaml
│   ├── ingress.yaml
│   └── volsync/
├── radarr/
│   ├── kustomization.yaml
│   ├── helm-release.yaml
│   ├── pvc.yaml
│   ├── ingress.yaml
│   └── volsync/
├── qbittorrent-app.yaml                  # ArgoCD Application
├── prowlarr-app.yaml                     # ArgoCD Application
├── sonarr-app.yaml                       # ArgoCD Application
├── radarr-app.yaml                       # ArgoCD Application
└── README.md                             # Usage guide
```

**Note:** No `namespace.yaml` - namespace managed via ArgoCD `CreateNamespace=true` syncOption

## ArgoCD Application Pattern

Each app follows this pattern (example for qBittorrent):

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: qbittorrent
  namespace: argocd
spec:
  project: default
  source:
    path: base/apps/media/qbittorrent
    repoURL: https://forge.internal/nemo/home-ops.git
    targetRevision: HEAD
  destination:
    namespace: media
    name: 'in-cluster'
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## Bitwarden Setup Requirements

### Required Bitwarden Item
**Name:** "Media Stack"
**Item ID:** (to be created - will be added here after creation)

**Required Fields:**

1. **ProtonVPN Configuration:**
   - `PROTONVPN_OPENVPN_USERNAME` - ProtonVPN OpenVPN username
   - `PROTONVPN_OPENVPN_PASSWORD` - ProtonVPN OpenVPN password
   - OR
   - `PROTONVPN_WIREGUARD_PRIVATE_KEY` - Wireguard private key (if using Wireguard)
   - `PROTONVPN_WIREGUARD_ADDRESS` - Wireguard address (if using Wireguard)

2. **qBittorrent Credentials:**
   - `QBITTORRENT_USERNAME` - Web UI username (suggest: admin)
   - `QBITTORRENT_PASSWORD` - Web UI password (generate strong password)

3. **API Keys (generated after first startup, store for reference):**
   - `PROWLARR_API_KEY` - Generated after first Prowlarr startup
   - `SONARR_API_KEY` - Generated after first Sonarr startup
   - `RADARR_API_KEY` - Generated after first Radarr startup

### ProtonVPN Setup Steps

1. **Get OpenVPN Credentials:**
   - Login to ProtonVPN account: https://account.protonvpn.com
   - Go to Account → OpenVPN/IKEv2 username/password
   - **Important:** These are different from web login credentials
   - Format: `username+pmp` / random password

2. **Alternative: Wireguard Setup:**
   - Download Wireguard config from ProtonVPN
   - Extract private key and address from config file
   - Generally faster than OpenVPN

3. **Recommended Servers:**
   - Choose P2P-optimized servers
   - Preferably in privacy-friendly jurisdictions (NL, CH, IS)
   - Server selection via `SERVER_COUNTRIES` env var

## Configuration Notes

### Gluetun Environment Variables
```yaml
VPN_SERVICE_PROVIDER: protonvpn
VPN_TYPE: openvpn               # or wireguard
OPENVPN_USER: <from bitwarden>
OPENVPN_PASSWORD: <from bitwarden>
SERVER_COUNTRIES: Netherlands   # or preferred country
FIREWALL_OUTBOUND_SUBNETS: 10.0.0.0/8  # Allow cluster network
HTTPPROXY: "off"                # Disable HTTP proxy
SHADOWSOCKS: "off"              # Disable Shadowsocks
```

### qBittorrent Configuration
```yaml
Environment:
  QBITTORRENT__PORT: "8080"
  QBITTORRENT__BT_PORT: "6881"  # Will be forwarded through VPN

Persistence:
  config: /config                # Longhorn PVC
  downloads: /data/torrents      # NFS mount to /tank/Media/torrents
```

### Sonarr Configuration
```yaml
Persistence:
  config: /config                        # Longhorn PVC
  downloads: /data/torrents              # NFS: /tank/Media/torrents
  series: /data/media/Series             # NFS: /tank/Media/Series
```

### Radarr Configuration
```yaml
Persistence:
  config: /config                        # Longhorn PVC
  downloads: /data/torrents              # NFS: /tank/Media/torrents
  movies: /data/media/Movies             # NFS: /tank/Media/Movies
```

### NZBGet Configuration
```yaml
Persistence:
  config: /config                        # Longhorn PVC
  downloads: /data/torrents              # NFS: /tank/Media/torrents (shared with qBittorrent)
  series: /data/media/Series             # NFS: /tank/Media/Series
  movies: /data/media/Movies             # NFS: /tank/Media/Movies

Environment:
  NZBGET_USER: admin
  NZBGET_PASS: <from bitwarden>
```

### Network Flow
```
Internet → ProtonVPN → Gluetun → qBittorrent (pod)
                                     ↑
Internet (SSL/TLS) → NZBGet (pod) ───┤
                                     |
                                     | (cluster network)
                                     |
Prowlarr ─────────────────────────────┤
Sonarr   ─────────────────────────────┤
Radarr   ─────────────────────────────┘
```

**Important:**
- Only qBittorrent traffic goes through VPN (torrent protocol requires privacy)
- NZBGet uses direct encrypted SSL/TLS connections to Usenet servers (no VPN needed)
- Prowlarr, Sonarr, and Radarr communicate with download clients over the cluster network (10.0.0.0/8)

## Helm Charts Used

All apps use **bjw-s/app-template** chart (v3.x):
- Repo: `https://bjw-s.github.io/helm-charts`
- Highly flexible, supports sidecars, multiple containers
- Used throughout existing infrastructure
- Repo reference in ArgoCD: `bjw-s` (defined in flux-system or ArgoCD)

## Testing Procedures

### VPN Kill Switch Test
1. Deploy qBittorrent with Gluetun
2. Check VPN is connected:
   ```bash
   kubectl exec -n media <qbittorrent-pod> -c gluetun -- wget -qO- https://am.i.mullvad.net/json
   ```
3. Should show ProtonVPN IP, not your real IP
4. Kill VPN connection inside pod to test kill switch
5. Verify all traffic is blocked (kill switch working)

### Download Flow Test
1. Add indexer in Prowlarr (e.g., public tracker for testing)
2. Add Prowlarr to Sonarr/Radarr (via API key)
3. Search for content in Sonarr/Radarr
4. Verify request sent to qBittorrent
5. Monitor download progress in qBittorrent
6. Verify completed file moves to correct directory

### ArgoCD Sync Test
1. Make a minor change to a manifest
2. Commit and push to repo
3. Watch ArgoCD auto-sync
4. Verify changes applied to cluster

## Troubleshooting

### Common Issues

**VPN won't connect:**
- Verify ProtonVPN credentials in Bitwarden
- Check Gluetun logs: `kubectl logs -n media <pod> -c gluetun`
- Ensure `SERVER_COUNTRIES` or specific server is reachable
- Check if ProtonVPN account is active

**qBittorrent can't download:**
- Verify VPN is connected (see VPN test above)
- Check port forwarding if enabled
- Verify firewall rules allow cluster subnet
- Check qBittorrent logs: `kubectl logs -n media <pod> -c app`

**Apps can't reach qBittorrent:**
- Verify service name: `qbittorrent.media.svc.cluster.local`
- Check service port (default: 8080)
- Test connectivity: `kubectl exec -n media <pod> -- curl http://qbittorrent:8080`
- Verify network policies aren't blocking

**NFS mount fails:**
- Verify `cardinal.internal` is reachable from cluster nodes
- Check NFS export: `showmount -e cardinal.internal`
- Verify permissions on NFS share (should allow writes)
- Check pod events: `kubectl describe pod -n media <pod>`

**VolSync backup failing:**
- Check Restic repository credentials
- Verify backup schedule in VolSync component
- Check ReplicationSource status: `kubectl get replicationsource -n media`
- View VolSync logs: `kubectl logs -n volsync-system -l app=volsync`

**Ingress not accessible:**
- Verify nginx-internal ingress controller is running
- Check certificate is issued: `kubectl get certificate -n media`
- Verify DNS resolution for `*.internal`
- Check ingress whitelist allows your source IP

## Session Progress Log

### Session 1 - 2025-10-13
- [x] Created project documentation
- [x] Designed architecture
- [x] Created `base/apps/media/` directory
- [x] Verified NFS exports on cardinal.internal
- [x] Documented existing `/tank/Media` directory structure
- [x] Defined mount strategy for each app
- [ ] Next: Create Bitwarden item and qBittorrent manifests

### Session 2 - TBD
- Planned: Complete qBittorrent deployment with VPN
- Planned: Test VPN functionality thoroughly
- Planned: Deploy Prowlarr
- Planned: Begin Sonarr deployment

### Session 3 - TBD
- Planned: Complete Sonarr deployment
- Planned: Deploy Radarr
- Planned: Configure inter-app connections
- Planned: Test end-to-end download flow

### Session 4 - TBD
- Planned: ArgoCD integration verification
- Planned: Final testing and optimization
- Planned: Complete documentation

## Pre-Deployment Checklist

Before deploying to cluster:

1. **NFS Preparation:**
   - [ ] Create `/tank/Media/torrents` directory on cardinal.internal
   - [ ] Create `/tank/Media/torrents/incomplete` subdirectory
   - [ ] Create `/tank/Media/torrents/complete` subdirectory
   - [ ] Create `/tank/Media/torrents/watch` subdirectory (optional)
   - [ ] Set appropriate permissions (allow cluster to write)

2. **Bitwarden Preparation:**
   - [ ] Create "Media Stack" item in Bitwarden
   - [ ] Add ProtonVPN OpenVPN credentials
   - [ ] Generate and add qBittorrent web UI credentials
   - [ ] Note the Bitwarden item UUID for ExternalSecret references

3. **Repository Preparation:**
   - [ ] Ensure on `arr-stack` branch
   - [ ] All manifests created and validated
   - [ ] Kustomization files properly reference all resources
   - [ ] ArgoCD Application manifests created

## References

- [Gluetun Wiki](https://github.com/quia-vp/gluetun-wiki/wiki)
- [ProtonVPN OpenVPN Config](https://account.protonvpn.com/downloads)
- [bjw-s app-template docs](https://bjw-s.github.io/helm-charts/docs/app-template/)
- [VolSync component README](../base/components/volsync/README.md)
- [onedr0p/home-ops](https://github.com/onedr0p/home-ops) - Reference FluxCD setup
- [Prowlarr Wiki](https://wiki.servarr.com/prowlarr)
- [Sonarr Wiki](https://wiki.servarr.com/sonarr)
- [Radarr Wiki](https://wiki.servarr.com/radarr)
- [qBittorrent Documentation](https://github.com/qbittorrent/qBittorrent/wiki)

## Future Enhancements

### FlareSolverr (Cloudflare Bypass)

**Purpose:** Allows Prowlarr to access indexers protected by Cloudflare (e.g., 1337x, The Pirate Bay)

**Why needed:**
- Many popular public indexers use Cloudflare protection
- Cloudflare blocks automated requests (like those from Prowlarr)
- FlareSolverr acts as a proxy that solves Cloudflare challenges

**Implementation:**
- Simple container deployment (no special configuration needed)
- Image: `ghcr.io/flaresolverr/flaresolverr:latest`
- Prowlarr integrates via Settings → Indexers → Add FlareSolverr
- No VPN needed (just talks to indexers on behalf of Prowlarr)

**Configuration in Prowlarr:**
1. Settings → Indexers → FlareSolverr Tags
2. Add FlareSolverr endpoint: `http://flaresolverr.media.svc.cluster.local:8191`
3. Tag indexers that need Cloudflare bypass

**Resources:**
- ~100MB memory
- Minimal CPU usage
- Port: 8191

### Usenet/NZB Support (Priority: After Sonarr/Radarr completion)

**Why add Usenet:**
- Faster downloads (no seeding required)
- Better availability for older/obscure content
- Encrypted connections (no VPN needed)
- Complements torrent sources

**Options:**
1. **SABnzbd** (Recommended)
   - User-friendly web interface
   - Mature and well-documented
   - Good Sonarr/Radarr integration
   - Image: `lscr.io/linuxserver/sabnzbd`

2. **NZBGet**
   - Lighter weight, more efficient
   - Lower resource usage
   - Still actively maintained
   - Image: `lscr.io/linuxserver/nzbget`

**Requirements:**
- Usenet provider subscription (e.g., Newshosting, Eweka, Frugal Usenet)
- NZB indexer access (e.g., NZBGeek, NZBPlanet, or free indexers)
- Additional storage for incomplete downloads (`/tank/Media/usenet/incomplete`)

**Implementation Notes:**
- No VPN needed (Usenet uses SSL/TLS)
- Similar deployment pattern to qBittorrent (but simpler, no sidecar)
- Sonarr/Radarr can use both torrent and Usenet simultaneously
- NZB indexers can be managed through Prowlarr

## Next Steps for Current Session

1. Create Bitwarden "Media Stack" item with ProtonVPN credentials
2. Create `/tank/Media/torrents` directory structure on cardinal.internal
3. Begin qBittorrent implementation:
   - Create directory structure
   - Create ExternalSecrets
   - Create HelmRelease with Gluetun sidecar
   - Create PVC and ingress
   - Create kustomization.yaml
   - Create ArgoCD Application manifest

---
**Last Updated:** 2025-10-13
**Current Session:** 1
**Next Session TODO:** Test qBittorrent VPN, proceed with Prowlarr deployment
