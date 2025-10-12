# home-ops

> Because paying for cloud services is for people who hate tinkering at 2 AM

This is my homelab Kubernetes cluster, where I host everything I probably shouldn't be self-hosting but absolutely will anyway. Because why trust a reliable cloud provider when you can trust your own questionable infrastructure decisions?

## What's Running Here?

**Self-Hosted Services** (aka "Things I Stubbornly Refuse to Pay For")
- **Miniflux** - RSS reader (yes, RSS still exists)
- **SearXNG** - Private search engine (paranoia level: moderate)
- **Wallabag** - Read-it-later service
- **Mealie** - Recipe manager (for organizing recipes I'll never cook)
- **Wiki.js** - Documentation nobody will read
- **Homepage** - Dashboard to admire all my services

**Home Automation** (aka "Over-Engineering Light Switches")
- **Grafana** - Making pretty graphs of meaningless metrics
- **InfluxDB2** - Time-series database for data hoarding
- **RTL433** - Decoding wireless sensor data
- **RTLAMR2MQTT** - Reading utility meters like a creep
- **NUT (UPS Daemon)** - Because power outages are the enemy

**IRC** (Yes, Really)
- **Marmithon** - IRC bot (it's 2025 and I'm still on IRC, don't judge)

**Infrastructure** (The Boring But Necessary Bits)
- **CloudNative-PG** - PostgreSQL operator
- **Cert-Manager** - TLS certificates
- **External DNS** - DNS automation
- **Nginx Ingress** - Traffic routing
- **Longhorn** - Distributed storage
- **Prometheus Stack** - Observability (so I know what broke)
- **External Secrets** - Bitwarden integration
- **Kyverno** - Policy enforcement

## GitOps Journey

**Status**: Currently migrating from FluxCD to ArgoCD (almost done! 🎉)

This repo uses GitOps because manually applying YAMLs like a caveman is beneath us. We're sophisticated YAML engineers here.

## Standing on the Shoulders of Giants

Massive thanks to the incredible [k8s@home](https://discord.gg/k8s-at-home) community! Special shoutouts to:
- [onedr0p](https://github.com/onedr0p/) - For showing us how it's done
- [bjw-s](https://github.com/bjw-s-labs/) - For the amazing Helm charts

Without their repos to shamelessly copy from, this would have taken way longer.

## Quick Start

```bash
# List all available commands
just

# Bootstrap the cluster (if you're brave)
just k8s-bootstrap cluster="main"

# Update SOPS secrets
just sops-update

# Get kubeconfig
just k8s-get-kubeconfig
```

## Tech Stack

- **Kubernetes** - Because Docker Compose was too easy
- **ArgoCD** - GitOps the right way (eventually)
- **SOPS + Age** - Secrets management
- **External Secrets** - Bitwarden integration
- **Renovate** - Automated dependency updates

## Philosophy

If it's not in Git, it doesn't exist. If it's not automated, it's not production-ready. If it's not over-engineered, is it really a homelab?

---

*"It works on my cluster" - Famous last words*
