# WebRadio OpenWrt

A lightweight internet radio streaming stack for OpenWrt/ARM platforms.

## Overview

This project provides a complete webradio solution packaged as OpenWrt IPK packages:

- **Icecast** - Streaming media server
- **Ezstream** - Playlist source client for Icecast
- **luci-app-webradio** - LuCI web interface for control and configuration

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     OpenWrt Router                          │
│                                                             │
│  ┌─────────────┐       ┌─────────────┐                     │
│  │   Ezstream  │──────▶│   Icecast   │◀──── Listeners      │
│  │  (source)   │ MP3   │  (server)   │ HTTP                │
│  └─────────────┘       └─────────────┘                     │
│        │                     │                              │
│        │                     │                              │
│  ┌─────▼─────┐         ┌────▼─────┐                        │
│  │ /srv/     │         │ LuCI Web │                        │
│  │ webradio/ │         │ Interface│                        │
│  │ music/    │         └──────────┘                        │
│  └───────────┘                                              │
└─────────────────────────────────────────────────────────────┘
```

## Packages

### icecast

Icecast 2.4.4 streaming server compiled for OpenWrt.

**Dependencies:** libxml2, libxslt, libogg, libvorbis, libcurl, libopenssl

**Configuration:** `/etc/config/icecast` (UCI) → generates `/etc/icecast.xml`

### ezstream

Ezstream 1.0.2 source client for Icecast.

**Dependencies:** libxml2, libshout, libogg, libvorbis

**Configuration:** `/etc/config/ezstream` (UCI) → generates `/etc/ezstream.xml`

### luci-app-webradio

LuCI JavaScript interface for WebRadio management.

**Features:**
- Dashboard with status, listeners, now playing
- Server configuration (Icecast + Ezstream)
- Playlist management with shuffle/upload
- Start/Stop/Skip controls
- Built-in audio player

## Quick Start

```bash
# Install packages
opkg update
opkg install icecast ezstream luci-app-webradio

# Configure
uci set icecast.server.enabled='1'
uci set icecast.server.source_password='your_password'
uci set ezstream.source.enabled='1'
uci set ezstream.server.password='your_password'
uci commit

# Add music
mkdir -p /srv/webradio/music
# Copy MP3/OGG files to /srv/webradio/music/

# Generate playlist
/usr/lib/ezstream/playlist-manager.sh generate

# Start services
/etc/init.d/icecast start
/etc/init.d/ezstream start

# Access
# Web: http://router-ip:8000/
# Stream: http://router-ip:8000/live
# LuCI: http://router-ip/cgi-bin/luci/admin/services/webradio
```

## UCI Configuration

### Icecast (`/etc/config/icecast`)

```
config server 'server'
    option enabled '1'
    option hostname 'localhost'
    option port '8000'
    option admin_user 'admin'
    option admin_password 'secret'
    option source_password 'hackme'
    option max_listeners '32'
```

### Ezstream (`/etc/config/ezstream`)

```
config source 'source'
    option enabled '1'
    option name 'My Radio'

config server 'server'
    option hostname '127.0.0.1'
    option port '8000'
    option password 'hackme'
    option mount '/live'

config playlist 'playlist'
    option directory '/srv/webradio/music'
    option shuffle '1'
```

## Directory Structure

```
/srv/webradio/
├── music/          # Audio files (MP3, OGG, FLAC)
├── jingles/        # Jingle audio files
└── playlists/      # Generated playlists
    └── current.m3u
```

## Scheduling

The scheduling system allows you to create a programming grid with different shows at different times.

### Configuration

Edit `/etc/config/webradio`:

```
config scheduling 'scheduling'
    option enabled '1'
    option timezone 'Europe/Paris'

config schedule 'morning'
    option enabled '1'
    option name 'Morning Show'
    option start_time '06:00'
    option end_time '09:00'
    option days '12345'
    option playlist 'morning_mix'
    option jingle_before 'morning_intro.mp3'
```

Days: 0=Sunday, 1=Monday, ..., 6=Saturday
- `12345` = Weekdays (Mon-Fri)
- `06` = Weekends (Sat-Sun)
- `0123456` = Every day

### Scheduler Commands

```bash
# Generate cron entries from config
/usr/lib/webradio/scheduler.sh generate

# Show current playing show
/usr/lib/webradio/scheduler.sh current

# List all scheduled shows
/usr/lib/webradio/scheduler.sh list

# Play a jingle immediately
/usr/lib/webradio/scheduler.sh jingle morning_intro.mp3
```

## Live Input (DarkIce)

Stream live audio from a microphone or sound card to your radio station.

### Prerequisites

- USB microphone or USB sound card
- ALSA audio support (`kmod-usb-audio`, `alsa-utils`)

### Configuration

Edit `/etc/config/darkice`:

```
config darkice 'main'
    option enabled '1'

config input 'input'
    option device 'hw:0,0'
    option samplerate '44100'
    option channels '2'

config server 'server'
    option hostname '127.0.0.1'
    option port '8000'
    option password 'your_source_password'
    option mount '/live-input'

config stream 'stream'
    option format 'mp3'
    option bitrate '128'
    option name 'Live Stream'
```

### Commands

```bash
# List audio devices
cat /proc/asound/cards
arecord -l

# Test recording
arecord -D hw:0,0 -f cd -d 5 test.wav

# Start/stop live streaming
/etc/init.d/darkice start
/etc/init.d/darkice stop

# Adjust input volume
alsamixer
```

### Tips

- Use different mount points for live (`/live-input`) and playlist (`/live`) streams
- Stop ezstream before going live on the same mount point
- Use `alsamixer` to adjust microphone input levels
- Monitor audio levels with `arecord -D hw:0,0 -vv -f cd /dev/null`

## Security & Hardening

### SSL/TLS Encryption

Enable HTTPS for secure streaming:

```bash
# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/icecast.key \
    -out /etc/ssl/certs/icecast.pem \
    -subj "/CN=myradio.local"

# Enable SSL in UCI
uci set icecast.ssl=ssl
uci set icecast.ssl.enabled='1'
uci set icecast.ssl.port='8443'
uci set icecast.ssl.certificate='/etc/ssl/certs/icecast.pem'
uci set icecast.ssl.key='/etc/ssl/private/icecast.key'
uci commit icecast

# Restart Icecast
/etc/init.d/icecast restart
```

Listeners can now connect via: `https://hostname:8443/live`

### CrowdSec Integration

Protect against connection floods and bandwidth abuse:

```bash
# Install CrowdSec (if not already installed)
opkg install crowdsec crowdsec-firewall-bouncer

# Install Icecast rules
/usr/lib/webradio/crowdsec-install.sh install

# Check status
/usr/lib/webradio/crowdsec-install.sh status
```

CrowdSec provides:
- **Connection flood detection**: Blocks IPs making 20+ connections in 30 seconds
- **Bandwidth abuse detection**: Detects stream ripping (multiple parallel connections)
- **Automatic IP blocking**: Via firewall bouncer integration

### Rate Limiting

Configure connection limits in `/etc/config/icecast`:

```
config ratelimit 'ratelimit'
    option enabled '1'
    option client_timeout '30'
    option burst_size '65535'
    option queue_size '524288'
```

### Security Best Practices

1. **Change default passwords** immediately after installation
2. **Enable SSL/TLS** for all public-facing streams
3. **Enable CrowdSec** to automatically block abusive IPs
4. **Set reasonable listener limits** to prevent resource exhaustion
5. **Monitor logs** regularly: `/var/log/icecast/`
6. **Restrict source connections** to localhost via firewall rules

## Commands

```bash
# Playlist management
/usr/lib/ezstream/playlist-manager.sh generate   # Scan and create playlist
/usr/lib/ezstream/playlist-manager.sh list       # Show current playlist
/usr/lib/ezstream/playlist-manager.sh status     # Show stats

# Service control
/etc/init.d/icecast start|stop|restart|reload
/etc/init.d/ezstream start|stop|restart

# Skip to next track
kill -USR1 $(cat /var/run/ezstream.pid)

# Test with ffmpeg (manual source)
ffmpeg -re -i file.mp3 -c:a libmp3lame -b:a 128k \
  -f mp3 icecast://source:password@127.0.0.1:8000/live
```

## Resource Usage

- **RAM:** ~8-12 MB (Icecast + Ezstream)
- **CPU:** Minimal (no transcoding by default)
- **Storage:** Depends on music library

## Security

- Change default passwords immediately
- Icecast runs as non-root user (`icecast:icecast`)
- Source passwords never exposed in UCI export
- Rate limiting via OpenWrt firewall recommended

## Troubleshooting

```bash
# Check logs
logread | grep -i icecast
cat /var/log/icecast/error.log

# Test connectivity
curl http://127.0.0.1:8000/status-json.xsl

# Verify processes
pgrep -a icecast
pgrep -a ezstream
```

## License

GPL-2.0

## Author

Gerald Kerma - CyberMind.FR
