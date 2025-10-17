# Network Upgrade Planning

This document outlines options for upgrading the home network infrastructure to support 2.5 Gbps internet connectivity and improve NFS transfer speeds.

## Current Infrastructure

### Hardware
- **Internet:** 800 Mbps connection
- **Router:** 2.5 GbE capable
- **Switch:** MikroTik CSS326-24G-2S+RM
  - 24x 1 Gbps RJ45 ports
  - 2x 10G SFP+ ports
  - Power consumption: ~15-20W
  - Fanless operation
- **Kubernetes Nodes:** Orange Pi 5 Plus (multiple units)
  - Dual 2.5 GbE Ethernet ports (Realtek RTL8125BG)
  - Connected via PCIe for better performance
- **Storage Server:** Cardinal
  - 2.5 GbE Ethernet

### Current Performance
- **Internet downloads (NZBGet):** 70-80 MB/s (~560-640 Mbps)
  - Utilization: 70-80% of 800 Mbps connection
- **NFS transfers:** Limited to ~110-115 MB/s (1 Gbps switch bottleneck)
  - Orange Pi → Switch (1 Gbps) → Cardinal server
  - Both endpoints are 2.5 GbE capable but bottlenecked by switch

### Current Bottleneck
The 1 Gbps switch is the **only bottleneck** in the infrastructure:
- Router: 2.5 GbE ✓
- Nodes: 2.5 GbE ✓
- Storage: 2.5 GbE ✓
- **Switch: 1 Gbps ✗**

## Future Internet Upgrade

### Potential: 2.5 Gbps Connection
If upgrading to a 2.5 Gbps internet connection:

**Expected download speeds:**
- Theoretical maximum: 312.5 MB/s (2500 Mbps ÷ 8)
- Realistic with protocol overhead: 200-250 MB/s
- Limited by Usenet provider caps: 150-200 MB/s typical

**Requirements to utilize:**
- Must upgrade the 1 Gbps switch
- All other infrastructure already supports 2.5 Gbps

## Upgrade Options

### Option 1: Full Switch Replacement (SFP+ Based)

**MikroTik CRS326-24S+2Q+RM**
- **Ports:** 24x 10G SFP+ + 2x 40G QSFP+
- **Price:** ~$500-600
- **Additional costs:**
  - 2.5G SFP+ to RJ45 transceivers: ~$15-30 each
  - Need 6-8 transceivers: $120-240
  - **Total: $620-840**
- **Power consumption:** 42W (idle) to 69W (loaded)
  - Annual electricity cost: ~$66/year (~$42/year more than current)
- **Cooling:** Active (fans) - generates noise
- **Pros:**
  - Future-proof (10G capable)
  - Stays in MikroTik ecosystem
  - Can mix 1G/2.5G/5G/10G speeds per port
- **Cons:**
  - Expensive upfront and ongoing (power)
  - Requires buying transceivers individually
  - Noisy (active cooling)
  - Higher power consumption

### Option 2: Hybrid Approach (Recommended)

**Setup:**
- Keep existing CSS326-24G-2S+RM for regular devices
- Add small 2.5 GbE switch for high-performance devices
- Connect via 10G SFP+ link between switches

**High-performance devices for 2.5 GbE switch:**
- Orange Pi 5+ Kubernetes nodes (3-4 units)
- Cardinal NFS storage server
- Router uplink
- Total needed: ~5-8 ports

**Small Switch Options:**

#### Budget: QNAP QSW-1105-5T
- **Ports:** 5x 2.5 GbE RJ45
- **Price:** ~$100-130
- **Power:** ~10W
- **Cooling:** Fanless (silent)
- **Annual electricity:** ~$13/year
- **Pros:** Very affordable, fanless, native RJ45
- **Cons:** Only 5 ports (may be tight)

#### Mid-range: TRENDnet TEG-S762
- **Ports:** 6x 2.5 GbE + 2x 10G SFP+
- **Price:** ~$200
- **Power:** ~12W
- **Cooling:** Fanless
- **Pros:** Extra 10G uplinks, good port count
- **Cons:** Mid-range price

#### Managed: Netgear MS510TXM
- **Ports:** 8x 2.5 GbE + 2x 10G SFP+
- **Price:** ~$350-400
- **Power:** ~15W
- **Cooling:** Fanless
- **Pros:** Managed features, plenty of ports, multiple 10G uplinks
- **Cons:** Higher price

**Hybrid Approach Benefits:**
- **Cost:** $100-400 one-time (no transceivers needed)
- **Power:** Only ~$2-3/year additional electricity
- **Noise:** Fanless options available
- **Flexibility:** Keep existing 24-port switch for most devices
- **Performance:** 2.5 Gbps where it matters most

**Hybrid Approach Topology:**
```
Internet (2.5 Gbps)
    |
Router (2.5 GbE)
    |
    ├─── 2.5 GbE Switch (high-performance)
    |    ├─ Orange Pi nodes (2.5 GbE)
    |    ├─ Cardinal server (2.5 GbE)
    |    └─ 10G SFP+ link to CSS326
    |
    └─── CSS326 (1 Gbps) (everything else)
         └─ 22+ other devices
```

### Option 3: Native 24-Port 2.5 GbE Switch

**TP-Link TL-SG3428XPP-M2**
- **Ports:** 24x 2.5 GbE PoE++ + 4x 10G SFP+
- **Price:** ~$800-1000
- **Power:** Higher (PoE capable)
- **Pros:** Native RJ45, PoE support, fully managed
- **Cons:** Very expensive, overkill for most home use

**Netgear M4350 Series**
- **Ports:** 24x 2.5 GbE options available
- **Price:** ~$1000-1500
- **Pros:** Enterprise features
- **Cons:** Expensive, enterprise-focused

## Performance Impact Analysis

### Current State (1 Gbps Switch)
- Internet downloads: 70-80 MB/s (limited by 800 Mbps connection)
- NFS transfers: 110-115 MB/s (limited by 1 Gbps switch)

### After 2.5 GbE Upgrade (Hybrid or Full)
- Internet downloads (with 2.5 Gbps internet): 150-250 MB/s
  - Realistic: 150-200 MB/s (limited by Usenet providers)
- NFS transfers: 280-290 MB/s (2.5x improvement)
- Local transfers between nodes: 280-290 MB/s

### Benefits Even Without Internet Upgrade
Upgrading the switch provides **immediate benefits** even with current 800 Mbps internet:
- **NFS performance:** 2.5x faster transfers (110 MB/s → 280 MB/s)
  - Faster media file imports from NZBGet to NFS
  - Faster backups to Cardinal server
  - Better performance for Longhorn storage replication
- **Local cluster traffic:** 2.5x faster inter-node communication

## Media Stack Specific Impact

### Current NZBGet Workflow
1. **Download & Extract:** Local OpenEBS storage at `/data/Downloads` (~70-80 MB/s)
2. **Move to NFS:** Complete files → `/data/torrents/complete` (NFS, limited to 110 MB/s)
3. **Import:** Sonarr/Radarr import from NFS (limited to 110 MB/s)
4. **Organize:** Final files → `/data/media/Movies` or `/data/media/Series` (NFS)

### After 2.5 GbE Upgrade
1. **Download & Extract:** Local OpenEBS storage (~150-200 MB/s with faster internet)
2. **Move to NFS:** Complete files → NFS at ~280 MB/s (2.5x faster)
3. **Import:** Sonarr/Radarr import at ~280 MB/s (2.5x faster)
4. **Organize:** Final files → NFS at ~280 MB/s

**Time savings example:**
- 50 GB movie file moved to NFS:
  - Current: 50GB ÷ 110 MB/s = ~7.5 minutes
  - After upgrade: 50GB ÷ 280 MB/s = ~3 minutes
  - **Savings: ~4.5 minutes per large file**

## Recommendation

**Recommended approach: Option 2 (Hybrid)**

**Rationale:**
1. **Cost-effective:** $100-400 vs $800-1500
2. **Immediate NFS benefits:** Even without internet upgrade
3. **Low power consumption:** Only ~$2-3/year extra electricity
4. **Silent operation:** Fanless options available
5. **Flexible:** Can upgrade to full 2.5 GbE later if needed
6. **Adequate capacity:** Only 5-8 devices truly need 2.5 Gbps

**Suggested product:** TRENDnet TEG-S762 (~$200)
- 6x 2.5 GbE ports (enough for nodes + Cardinal + router)
- 2x 10G SFP+ uplinks (redundant connections to CSS326)
- Fanless operation
- Good price/performance ratio

## Implementation Plan

### Phase 1: Purchase and Setup
1. Purchase TRENDnet TEG-S762 or similar 2.5 GbE switch
2. Connect 10G SFP+ link between new switch and CSS326
   - Use existing SFP+ ports on CSS326
   - Purchase 10G SFP+ modules or DAC cable if needed (~$20-50)

### Phase 2: Migration
1. Move high-performance devices to new switch:
   - Orange Pi 5+ nodes (one at a time to minimize disruption)
   - Cardinal storage server
   - Router connection
2. Verify 2.5 Gbps link negotiation on all devices
3. Test NFS performance (expect ~280 MB/s)

### Phase 3: Optimization
1. Monitor network performance
2. Verify no bottlenecks in cluster
3. Consider internet upgrade to 2.5 Gbps if available

### Phase 4: Future Expansion (Optional)
If more devices need 2.5 Gbps:
- Add another small 2.5 GbE switch
- Or upgrade to full 24-port 2.5 GbE switch
- Keep hybrid approach working in the meantime

## Cost Summary

### One-Time Costs
| Item | Cost |
|------|------|
| TRENDnet TEG-S762 switch | $200 |
| 10G SFP+ modules/cable | $20-50 |
| **Total** | **$220-250** |

### Ongoing Costs
| Item | Annual Cost |
|------|-------------|
| Electricity (~12W) | ~$2-3 |

### Return on Investment
- **Immediate:** 2.5x faster NFS transfers
- **Future:** Can utilize 2.5 Gbps internet when available
- **Payback period:** Qualitative (performance improvement)

## Alternative: Do Nothing

**Cost:** $0
**Performance:**
- Keep current 70-80 MB/s download speeds
- Keep current 110 MB/s NFS transfer speeds
- Cannot utilize faster internet if/when available

**This is viable if:**
- Current performance is acceptable
- No plans for faster internet
- Budget constraints

## Notes

### Orange Pi 5 Plus Network Capabilities
- Dual 2.5 GbE ports per device
- Realtek RTL8125BG chipset
- PCIe-connected (better performance than USB)
- Potential future use: Bond both ports for 5 Gbps (with LACP-capable switch)

### Current NZBGet Optimization
Recent optimization (October 2024):
- Changed from NFS to OpenEBS hostpath for `/data/Downloads`
- Downloads now use local fast storage (200 Gi PVC)
- Completed files moved to NFS for Sonarr/Radarr access
- Improved download speeds from 30-50 MB/s to 70-80 MB/s

## References

- MikroTik CSS326-24G-2S+RM: Current switch documentation
- MikroTik CRS326-24S+2Q+RM: Alternative full switch replacement
- Orange Pi 5 Plus specifications: http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-5-plus.html
- TRENDnet TEG-S762: Recommended 2.5 GbE switch option

---
**Document created:** 2024-10-16
**Last updated:** 2024-10-16
**Status:** Planning phase
