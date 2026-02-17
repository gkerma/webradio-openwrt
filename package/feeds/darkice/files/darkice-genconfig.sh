#!/bin/sh
# Generate DarkIce configuration from UCI
# Copyright (C) 2024 CyberMind.FR

. /lib/functions.sh

CONFIG="darkice"

# Load UCI config
config_load "$CONFIG"

# Input settings
config_get device input device "hw:0,0"
config_get samplerate input samplerate "44100"
config_get bitspersample input bitspersample "16"
config_get channels input channels "2"

# Server settings
config_get hostname server hostname "127.0.0.1"
config_get port server port "8000"
config_get password server password "hackme"
config_get mount server mount "/live"

# Stream settings
config_get format stream format "mp3"
config_get bitrate stream bitrate "128"
config_get quality stream quality "0.8"
config_get name stream name "Live Stream"
config_get description stream description "Live audio from WebRadio"
config_get genre stream genre "Live"
config_get url stream url ""
config_get public stream public "0"

# Generate darkice.cfg
cat << EOF
# DarkIce configuration file
# Auto-generated from /etc/config/darkice
# Do not edit directly

[general]
duration        = 0
bufferSecs      = 5
reconnect       = yes

[input]
device          = $device
sampleRate      = $samplerate
bitsPerSample   = $bitspersample
channel         = $channels

[icecast2-0]
bitrateMode     = cbr
EOF

# Format-specific encoding
case "$format" in
	mp3)
		cat << EOF
format          = mp3
bitrate         = $bitrate
quality         = $quality
EOF
		;;
	ogg|vorbis)
		cat << EOF
format          = vorbis
bitrate         = $bitrate
quality         = $quality
EOF
		;;
esac

# Server connection
cat << EOF
server          = $hostname
port            = $port
password        = $password
mountPoint      = $mount
name            = $name
description     = $description
genre           = $genre
EOF

[ -n "$url" ] && echo "url             = $url"

cat << EOF
public          = $public
EOF
