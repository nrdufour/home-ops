# *arr Stack Configuration Guide

This guide walks through configuring the *arr stack after initial deployment.

## Prerequisites

All applications should be running and accessible:
- qBittorrent: `https://qbittorrent.internal`
- Prowlarr: `https://prowlarr.internal`
- Sonarr: `https://sonarr.internal`
- Radarr: `https://radarr.internal`

## Step 1: Collect API Keys

Each *arr application generates a unique API key on first startup. You'll need these for inter-app communication.

### Prowlarr API Key

1. Navigate to `https://prowlarr.internal`
2. Go to **Settings → General → Security**
3. Copy the **API Key**
4. Save to Bitwarden under "Media Stack" item as `PROWLARR_API_KEY`

### Sonarr API Key

1. Navigate to `https://sonarr.internal`
2. Go to **Settings → General → Security**
3. Copy the **API Key**
4. Save to Bitwarden under "Media Stack" item as `SONARR_API_KEY`

### Radarr API Key

1. Navigate to `https://radarr.internal`
2. Go to **Settings → General → Security**
3. Copy the **API Key**
4. Save to Bitwarden under "Media Stack" item as `RADARR_API_KEY`

## Step 2: Configure Root Folders

Root folders define where media files are stored.

### Sonarr Root Folder

1. Navigate to `https://sonarr.internal`
2. Go to **Settings → Media Management**
3. Scroll to **Root Folders** section
4. Click **Add Root Folder (+)**
5. Enter path: `/data/media/Series`
6. Click **OK**

### Radarr Root Folder

1. Navigate to `https://radarr.internal`
2. Go to **Settings → Media Management**
3. Scroll to **Root Folders** section
4. Click **Add Root Folder (+)**
5. Enter path: `/data/media/Movies`
6. Click **OK**

## Step 3: Connect Prowlarr to Sonarr

Prowlarr manages indexers centrally and syncs them to Sonarr and Radarr.

1. Navigate to `https://prowlarr.internal`
2. Go to **Settings → Apps**
3. Click **Add Application (+)**
4. Select **Sonarr**
5. Configure:
   - **Name:** `Sonarr`
   - **Sync Level:** `Full Sync`
   - **Tags:** (leave empty for all indexers)
   - **Prowlarr Server:** `http://localhost:9696`
   - **Sonarr Server:** `http://sonarr.media.svc.cluster.local:8989`
   - **API Key:** (Paste Sonarr's API key from Step 1)
6. Click **Test** to verify connection
7. Click **Save**

## Step 4: Connect Prowlarr to Radarr

1. Navigate to `https://prowlarr.internal`
2. Go to **Settings → Apps**
3. Click **Add Application (+)**
4. Select **Radarr**
5. Configure:
   - **Name:** `Radarr`
   - **Sync Level:** `Full Sync`
   - **Tags:** (leave empty for all indexers)
   - **Prowlarr Server:** `http://localhost:9696`
   - **Radarr Server:** `http://radarr.media.svc.cluster.local:7878`
   - **API Key:** (Paste Radarr's API key from Step 1)
6. Click **Test** to verify connection
7. Click **Save**

## Step 5: Add qBittorrent to Sonarr

1. Navigate to `https://sonarr.internal`
2. Go to **Settings → Download Clients**
3. Click **Add (+)**
4. Select **qBittorrent**
5. Configure:
   - **Name:** `qBittorrent`
   - **Enable:** ✓ (checked)
   - **Host:** `qbittorrent.media.svc.cluster.local`
   - **Port:** `8080`
   - **Username:** `admin` (from Bitwarden)
   - **Password:** (from Bitwarden `QBITTORRENT_PASSWORD`)
   - **Category:** `sonarr` (optional but recommended)
   - **Post-Import Category:** (leave empty)
   - **Recent Priority:** `Last`
   - **Older Priority:** `Last`
   - **Initial State:** `Start`
6. Click **Test** to verify connection
7. Click **Save**

## Step 6: Add qBittorrent to Radarr

1. Navigate to `https://radarr.internal`
2. Go to **Settings → Download Clients**
3. Click **Add (+)**
4. Select **qBittorrent**
5. Configure:
   - **Name:** `qBittorrent`
   - **Enable:** ✓ (checked)
   - **Host:** `qbittorrent.media.svc.cluster.local`
   - **Port:** `8080`
   - **Username:** `admin` (from Bitwarden)
   - **Password:** (from Bitwarden `QBITTORRENT_PASSWORD`)
   - **Category:** `radarr` (optional but recommended)
   - **Post-Import Category:** (leave empty)
   - **Recent Priority:** `Last`
   - **Older Priority:** `Last`
   - **Initial State:** `Start`
6. Click **Test** to verify connection
7. Click **Save**

## Step 7: Add Indexers in Prowlarr

Indexers are torrent trackers or sites where content is indexed.

### Adding Public Indexers (for testing)

1. Navigate to `https://prowlarr.internal`
2. Go to **Indexers**
3. Click **Add Indexer (+)**
4. Search for public indexers:
   - **1337x** (popular public tracker)
   - **The Pirate Bay** (if available in your region)
   - **EZTV** (TV shows focused)
   - **YTS** (movies focused)
5. For each indexer:
   - Select the indexer from the list
   - Configure any required settings (usually minimal for public indexers)
   - Set **Categories** if you want to filter (optional)
   - Click **Test**
   - Click **Save**

### Adding Private Indexers (optional)

1. Click **Add Indexer (+)**
2. Search for your private tracker by name
3. Configure:
   - Enter your tracker credentials (username, passkey, cookie, etc.)
   - Set appropriate categories
   - Click **Test**
   - Click **Save**

**Note:** Once indexers are added in Prowlarr, they automatically sync to Sonarr and Radarr (configured in Steps 3-4).

## Step 8: Configure Download Paths (Recommended)

### Sonarr Download Path Settings

1. Navigate to `https://sonarr.internal`
2. Go to **Settings → Media Management**
3. Configure:
   - **Episode Naming:** Configure your preferred naming scheme
   - **Importing:**
     - **Use Hardlinks instead of Copy:** ✓ (recommended - saves space)
   - **File Management:**
     - **Ignore Deleted Episodes:** ✓ (recommended)
     - **Unmonitor Deleted Episodes:** ✓ (recommended)

### Radarr Download Path Settings

1. Navigate to `https://radarr.internal`
2. Go to **Settings → Media Management**
3. Configure:
   - **Movie Naming:** Configure your preferred naming scheme
   - **Importing:**
     - **Use Hardlinks instead of Copy:** ✓ (recommended - saves space)
   - **File Management:**
     - **Ignore Deleted Movies:** ✓ (recommended)
     - **Unmonitor Deleted Movies:** ✓ (recommended)

## Step 9: Test the Download Flow

### Test TV Show Download (Sonarr)

1. Navigate to `https://sonarr.internal`
2. Click **Add New** (or search icon)
3. Search for a TV show (e.g., "Big Buck Bunny" for testing)
4. Click on the show
5. Configure:
   - **Root Folder:** `/data/media/Series`
   - **Quality Profile:** Any (or create custom)
   - **Series Type:** Standard
   - **Season Folder:** ✓ (recommended)
   - **Monitoring:** All Episodes (or your preference)
6. Click **Add Series**
7. Click **Search** to trigger a download
8. Monitor progress:
   - Go to **Activity → Queue** to see download progress
   - Check qBittorrent at `https://qbittorrent.internal` to see the torrent
9. Once complete, verify:
   - File appears in `/tank/Media/Series/[ShowName]/`
   - Episode is marked as downloaded in Sonarr

### Test Movie Download (Radarr)

1. Navigate to `https://radarr.internal`
2. Click **Add New** (or search icon)
3. Search for a movie (e.g., "Big Buck Bunny" for testing)
4. Click on the movie
5. Configure:
   - **Root Folder:** `/data/media/Movies`
   - **Quality Profile:** Any (or create custom)
   - **Monitoring:** Yes
6. Click **Add Movie**
7. Click **Search** to trigger a download
8. Monitor progress:
   - Go to **Activity → Queue** to see download progress
   - Check qBittorrent at `https://qbittorrent.internal` to see the torrent
9. Once complete, verify:
   - File appears in `/tank/Media/Movies/[MovieName]/`
   - Movie is marked as downloaded in Radarr

## Step 10: Verify VPN Protection (Important!)

Ensure torrent traffic is going through the VPN:

```bash
# Check qBittorrent is using VPN IP
kubectl logs -n media deployment/qbittorrent -c qbittorrent | grep "Detected external IP"

# Check Gluetun VPN connection
kubectl logs -n media deployment/qbittorrent -c gluetun | grep "Public IP"
```

The detected IP should be a ProtonVPN IP (Iceland), NOT your real IP.

## Troubleshooting

### Connection Test Failures

**Sonarr/Radarr can't reach qBittorrent:**
- Verify qBittorrent pod is running: `kubectl get pods -n media -l app=qbittorrent`
- Check service exists: `kubectl get svc -n media qbittorrent`
- Verify credentials match those in Bitwarden
- Check qBittorrent Web UI is accessible from within cluster:
  ```bash
  kubectl run -n media test-pod --rm -it --image=curlimages/curl -- \
    curl -v http://qbittorrent.media.svc.cluster.local:8080
  ```

**Prowlarr can't reach Sonarr/Radarr:**
- Verify API keys are correct (copy-paste from Settings → General → Security)
- Check service names are correct:
  - Sonarr: `http://sonarr.media.svc.cluster.local:8989`
  - Radarr: `http://radarr.media.svc.cluster.local:7878`
- Verify pods are running: `kubectl get pods -n media`

### No Search Results

**Prowlarr shows no indexers:**
- Add indexers in Prowlarr (Step 7)
- Verify indexers are enabled (green checkmark)
- Check indexer logs: Indexers → [IndexerName] → View Logs

**Sonarr/Radarr shows no indexers:**
- Verify Prowlarr apps are connected (Settings → Apps)
- Force sync: Prowlarr → Settings → Apps → [App] → Sync App Indexers
- Check that indexers in Prowlarr support the required categories (TV/Movies)

### Downloads Not Starting

**qBittorrent not receiving torrents:**
- Check Sonarr/Radarr Activity → Queue for errors
- Verify download client is enabled in Sonarr/Radarr
- Test download client connection
- Check qBittorrent logs:
  ```bash
  kubectl logs -n media deployment/qbittorrent -c qbittorrent
  ```

**Torrents stalled/no peers:**
- Verify VPN is connected (see Step 10)
- Check if indexer requires registration or ratio
- Try different indexers
- Verify port forwarding is working (check Gluetun logs)

### Files Not Moving to Media Folder

**Downloads complete but don't appear in Sonarr/Radarr:**
- Verify root folders are configured correctly (Step 2)
- Check Sonarr/Radarr has write permissions to `/data/media/Series` or `/data/media/Movies`
- Verify NFS mounts are working:
  ```bash
  kubectl exec -n media deployment/sonarr -- ls -la /data/media/Series
  kubectl exec -n media deployment/radarr -- ls -la /data/media/Movies
  ```
- Check import logs: Activity → History → Failed

### NFS Permission Issues

If you see permission errors:

1. Check NFS export permissions on cardinal.internal:
   ```bash
   ssh cardinal.internal
   ls -la /tank/Media/Series
   ls -la /tank/Media/Movies
   ls -la /tank/Media/torrents
   ```

2. Ensure directories are writable by UID 1000, GID 1000 (or group 100)

3. Fix permissions if needed:
   ```bash
   sudo chown -R 1000:1000 /tank/Media/Series
   sudo chown -R 1000:1000 /tank/Media/Movies
   sudo chown -R 1000:1000 /tank/Media/torrents
   sudo chmod -R 775 /tank/Media/Series
   sudo chmod -R 775 /tank/Media/Movies
   sudo chmod -R 775 /tank/Media/torrents
   ```

## Optional: Advanced Configuration

### Quality Profiles

Create custom quality profiles in Sonarr/Radarr:
- Settings → Profiles → Add Profile
- Configure preferred qualities, upgrades, language, etc.

### Naming Schemes

Customize file naming:
- Sonarr: Settings → Media Management → Episode Naming
- Radarr: Settings → Media Management → Movie Naming

### Notifications

Set up notifications for completed downloads:
- Settings → Connect → Add Notification
- Options: Discord, Slack, Email, Telegram, etc.

### Metadata & Artwork

Enable metadata and artwork downloads:
- Settings → Metadata
- Enable desired metadata consumers (Kodi, Emby, etc.)

## Next Steps

1. **Add your media library** - Import existing TV shows and movies
2. **Configure quality profiles** - Set preferred quality levels
3. **Set up automatic monitoring** - Let Sonarr/Radarr automatically grab new episodes/movies
4. **Add Usenet support** (optional) - Add SABnzbd or NZBGet for faster, more reliable downloads
5. **Add Bazarr** (optional) - Automatic subtitle downloads
6. **Configure Jellyfin** - Point Jellyfin to your media directories to watch content

## Reference Links

- [Prowlarr Wiki](https://wiki.servarr.com/prowlarr)
- [Sonarr Wiki](https://wiki.servarr.com/sonarr)
- [Radarr Wiki](https://wiki.servarr.com/radarr)
- [qBittorrent Documentation](https://github.com/qbittorrent/qBittorrent/wiki)
- [TRaSH Guides](https://trash-guides.info/) - Comprehensive *arr stack guides

---
**Last Updated:** 2025-10-13
