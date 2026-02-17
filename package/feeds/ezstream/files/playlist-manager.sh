#!/bin/sh
# Playlist manager for ezstream
# Copyright (C) 2024 CyberMind.FR

. /lib/functions.sh

CONFIG="ezstream"
MUSIC_DIR="/srv/webradio/music"
PLAYLIST_DIR="/srv/webradio/playlists"
CURRENT_PLAYLIST="$PLAYLIST_DIR/current.m3u"

# Load config
load_playlist_config() {
	config_load "$CONFIG"
	config_get MUSIC_DIR playlist directory "$MUSIC_DIR"
	config_get PLAYLIST_FILE playlist playlist_file "$CURRENT_PLAYLIST"
	config_get SHUFFLE playlist shuffle "1"
}

# Generate playlist from music directory
generate_playlist() {
	load_playlist_config

	mkdir -p "$PLAYLIST_DIR"

	echo "Scanning $MUSIC_DIR for audio files..."

	# Find all supported audio files
	find "$MUSIC_DIR" -type f \( \
		-iname "*.mp3" -o \
		-iname "*.ogg" -o \
		-iname "*.flac" -o \
		-iname "*.wav" -o \
		-iname "*.m4a" -o \
		-iname "*.aac" \
	\) 2>/dev/null > "$PLAYLIST_DIR/all_tracks.tmp"

	local count=$(wc -l < "$PLAYLIST_DIR/all_tracks.tmp")
	echo "Found $count audio files"

	if [ "$count" -eq 0 ]; then
		echo "Warning: No audio files found in $MUSIC_DIR"
		# Create empty playlist
		echo "# Empty playlist - add files to $MUSIC_DIR" > "$PLAYLIST_FILE"
		rm -f "$PLAYLIST_DIR/all_tracks.tmp"
		return 1
	fi

	# Shuffle if enabled
	if [ "$SHUFFLE" = "1" ]; then
		echo "Shuffling playlist..."
		if command -v shuf >/dev/null 2>&1; then
			shuf "$PLAYLIST_DIR/all_tracks.tmp" > "$PLAYLIST_FILE"
		else
			# BusyBox fallback: use awk for pseudo-shuffle
			awk 'BEGIN{srand()} {print rand()"\t"$0}' "$PLAYLIST_DIR/all_tracks.tmp" | \
				sort -n | cut -f2- > "$PLAYLIST_FILE"
		fi
	else
		# Sort alphabetically
		sort "$PLAYLIST_DIR/all_tracks.tmp" > "$PLAYLIST_FILE"
	fi

	rm -f "$PLAYLIST_DIR/all_tracks.tmp"

	echo "Playlist generated: $PLAYLIST_FILE ($count tracks)"
}

# Add files to playlist
add_files() {
	local files="$*"
	load_playlist_config

	for file in $files; do
		if [ -f "$file" ]; then
			echo "$file" >> "$PLAYLIST_FILE"
			echo "Added: $file"
		else
			echo "File not found: $file"
		fi
	done
}

# Remove files from playlist
remove_files() {
	local pattern="$1"
	load_playlist_config

	if [ -f "$PLAYLIST_FILE" ]; then
		grep -v "$pattern" "$PLAYLIST_FILE" > "$PLAYLIST_FILE.tmp"
		mv "$PLAYLIST_FILE.tmp" "$PLAYLIST_FILE"
		echo "Removed tracks matching: $pattern"
	fi
}

# List current playlist
list_playlist() {
	load_playlist_config

	if [ -f "$PLAYLIST_FILE" ]; then
		local count=$(wc -l < "$PLAYLIST_FILE")
		echo "Current playlist: $PLAYLIST_FILE ($count tracks)"
		echo "---"
		cat -n "$PLAYLIST_FILE" | head -20
		[ "$count" -gt 20 ] && echo "... and $((count - 20)) more"
	else
		echo "No playlist found at $PLAYLIST_FILE"
	fi
}

# Show status
show_status() {
	load_playlist_config

	echo "Music directory: $MUSIC_DIR"
	echo "Playlist file: $PLAYLIST_FILE"

	if [ -d "$MUSIC_DIR" ]; then
		local total=$(find "$MUSIC_DIR" -type f \( -iname "*.mp3" -o -iname "*.ogg" -o -iname "*.flac" \) 2>/dev/null | wc -l)
		echo "Total audio files: $total"
	fi

	if [ -f "$PLAYLIST_FILE" ]; then
		local playlist_count=$(wc -l < "$PLAYLIST_FILE")
		echo "Playlist tracks: $playlist_count"
	else
		echo "Playlist: not generated"
	fi

	# Check disk space
	local avail=$(df -h "$MUSIC_DIR" 2>/dev/null | awk 'NR==2{print $4}')
	echo "Available space: $avail"
}

# Clear playlist
clear_playlist() {
	load_playlist_config
	echo "# Empty playlist" > "$PLAYLIST_FILE"
	echo "Playlist cleared"
}

# Create named playlist
create_named() {
	local name="$1"
	shift
	local files="$*"

	load_playlist_config
	local playlist="$PLAYLIST_DIR/${name}.m3u"

	> "$playlist"
	for file in $files; do
		[ -f "$file" ] && echo "$file" >> "$playlist"
	done

	echo "Created playlist: $playlist"
}

# Switch to named playlist
use_playlist() {
	local name="$1"
	load_playlist_config

	local playlist="$PLAYLIST_DIR/${name}.m3u"
	if [ -f "$playlist" ]; then
		cp "$playlist" "$PLAYLIST_FILE"
		echo "Switched to playlist: $name"
	else
		echo "Playlist not found: $playlist"
		return 1
	fi
}

# List available playlists
list_playlists() {
	load_playlist_config

	echo "Available playlists in $PLAYLIST_DIR:"
	ls -1 "$PLAYLIST_DIR"/*.m3u 2>/dev/null | while read pl; do
		local name=$(basename "$pl" .m3u)
		local count=$(wc -l < "$pl")
		echo "  $name ($count tracks)"
	done
}

# Usage
usage() {
	cat << EOF
Playlist Manager for ezstream

Usage: $0 <command> [args]

Commands:
  generate              Scan music directory and generate playlist
  list                  List current playlist contents
  status                Show playlist and storage status
  clear                 Clear current playlist
  add <files...>        Add files to current playlist
  remove <pattern>      Remove tracks matching pattern
  create <name> <files> Create named playlist
  use <name>            Switch to named playlist
  playlists             List available playlists

Directories:
  Music:     $MUSIC_DIR
  Playlists: $PLAYLIST_DIR

EOF
}

# Main
case "$1" in
	generate)
		generate_playlist
		;;
	list)
		list_playlist
		;;
	status)
		show_status
		;;
	clear)
		clear_playlist
		;;
	add)
		shift
		add_files "$@"
		;;
	remove)
		remove_files "$2"
		;;
	create)
		shift
		create_named "$@"
		;;
	use)
		use_playlist "$2"
		;;
	playlists)
		list_playlists
		;;
	*)
		usage
		;;
esac
