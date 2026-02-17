#!/bin/sh
# Generate ezstream.xml from UCI config
# Copyright (C) 2024 CyberMind.FR

. /lib/functions.sh

CONFIG="ezstream"
OUTPUT="/etc/ezstream.xml"

# Server defaults
server_hostname="127.0.0.1"
server_port="8000"
server_password="hackme"
server_mount="/live"
server_protocol="http"
server_tls="0"
server_reconnect="0"

# Stream defaults
stream_format="MP3"
stream_bitrate="128"
stream_samplerate="44100"
stream_channels="2"
stream_public="0"
stream_name="WebRadio"
stream_genre="Various"
stream_description="OpenWrt WebRadio"
stream_url=""

# Playlist defaults
playlist_type="files"
playlist_directory="/srv/webradio/music"
playlist_shuffle="1"
playlist_loop="1"
playlist_file="/srv/webradio/playlists/current.m3u"

# Metadata defaults
metadata_format="@a@ - @t@"
metadata_refresh="0"
metadata_normalize="1"
metadata_no_updates="0"

# Logging
log_verbosity="1"

load_server() {
	config_get server_hostname "$1" hostname "$server_hostname"
	config_get server_port "$1" port "$server_port"
	config_get server_password "$1" password "$server_password"
	config_get server_mount "$1" mount "$server_mount"
	config_get server_protocol "$1" protocol "$server_protocol"
	config_get server_tls "$1" tls "$server_tls"
	config_get server_reconnect "$1" reconnect_attempts "$server_reconnect"
}

load_stream() {
	config_get stream_format "$1" format "$stream_format"
	config_get stream_bitrate "$1" bitrate "$stream_bitrate"
	config_get stream_samplerate "$1" samplerate "$stream_samplerate"
	config_get stream_channels "$1" channels "$stream_channels"
	config_get stream_public "$1" public "$stream_public"
	config_get stream_name "$1" name "$stream_name"
	config_get stream_genre "$1" genre "$stream_genre"
	config_get stream_description "$1" description "$stream_description"
	config_get stream_url "$1" url "$stream_url"
}

load_playlist() {
	config_get playlist_type "$1" type "$playlist_type"
	config_get playlist_directory "$1" directory "$playlist_directory"
	config_get playlist_shuffle "$1" shuffle "$playlist_shuffle"
	config_get playlist_loop "$1" loop "$playlist_loop"
	config_get playlist_file "$1" playlist_file "$playlist_file"
}

load_metadata() {
	config_get metadata_format "$1" format_str "$metadata_format"
	config_get metadata_refresh "$1" refresh_interval "$metadata_refresh"
	config_get metadata_normalize "$1" normalize_strings "$metadata_normalize"
	config_get metadata_no_updates "$1" no_updates "$metadata_no_updates"
}

load_logging() {
	config_get log_verbosity "$1" verbosity "$log_verbosity"
}

generate_config() {
	# Determine intake type based on playlist type
	local intake_type="playlist"
	[ "$playlist_type" = "stdin" ] && intake_type="stdin"

	# Boolean conversions
	local shuffle_bool="false"
	[ "$playlist_shuffle" = "1" ] && shuffle_bool="true"

	local loop_bool="false"
	[ "$playlist_loop" = "1" ] && loop_bool="true"

	local public_bool="false"
	[ "$stream_public" = "1" ] && public_bool="true"

	local tls_str="none"
	[ "$server_tls" = "1" ] && tls_str="required"

	local normalize_bool="false"
	[ "$metadata_normalize" = "1" ] && normalize_bool="true"

	local no_updates_bool="false"
	[ "$metadata_no_updates" = "1" ] && no_updates_bool="true"

	cat > "$OUTPUT" << EOF
<!-- Ezstream configuration - Auto-generated from UCI -->
<!-- Do not edit directly, use /etc/config/ezstream -->
<ezstream>
    <servers>
        <server>
            <name>icecast</name>
            <protocol>$server_protocol</protocol>
            <hostname>$server_hostname</hostname>
            <port>$server_port</port>
            <password>$server_password</password>
            <tls>$tls_str</tls>
            <reconnect_attempts>$server_reconnect</reconnect_attempts>
        </server>
    </servers>

    <streams>
        <stream>
            <name>stream</name>
            <mountpoint>$server_mount</mountpoint>
            <public>$public_bool</public>
            <intake>playlist</intake>
            <server>icecast</server>
            <format>$stream_format</format>
            <stream_name>$stream_name</stream_name>
            <stream_url>$stream_url</stream_url>
            <stream_genre>$stream_genre</stream_genre>
            <stream_description>$stream_description</stream_description>
            <stream_bitrate>$stream_bitrate</stream_bitrate>
            <stream_samplerate>$stream_samplerate</stream_samplerate>
            <stream_channels>$stream_channels</stream_channels>
        </stream>
    </streams>

    <intakes>
        <intake>
            <name>playlist</name>
            <type>playlist</type>
            <filename>$playlist_file</filename>
            <shuffle>$shuffle_bool</shuffle>
            <stream_once>$( [ "$loop_bool" = "true" ] && echo "false" || echo "true" )</stream_once>
        </intake>
    </intakes>

    <metadata>
        <format_str>$metadata_format</format_str>
        <refresh_interval>$metadata_refresh</refresh_interval>
        <normalize_strings>$normalize_bool</normalize_strings>
        <no_updates>$no_updates_bool</no_updates>
    </metadata>
</ezstream>
EOF

	chmod 640 "$OUTPUT"
	echo "Generated $OUTPUT"
}

# Main
config_load "$CONFIG"

config_foreach load_server server
config_foreach load_stream stream
config_foreach load_playlist playlist
config_foreach load_metadata metadata
config_foreach load_logging logging

generate_config
