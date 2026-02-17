#!/bin/sh
# Generate icecast.xml from UCI config
# Copyright (C) 2024 CyberMind.FR

. /lib/functions.sh

CONFIG="icecast"
OUTPUT="/etc/icecast.xml"

# Default values
hostname="localhost"
port="8000"
admin_user="admin"
admin_password="hackme"
source_password="hackme"
relay_password="hackme"
max_listeners="32"
max_sources="4"
location="Earth"
admin_email="admin@localhost"

# Paths
basedir="/usr/share/icecast"
logdir="/var/log/icecast"
webroot="/usr/share/icecast/web"
adminroot="/usr/share/icecast/admin"

# Logging
loglevel="3"
accesslog="/var/log/icecast/access.log"
errorlog="/var/log/icecast/error.log"
logsize="10000"
logarchive="1"

# Security
chroot="0"
changeowner="1"
user="icecast"
group="icecast"

# SSL/TLS
ssl_enabled="0"
ssl_port="8443"
ssl_certificate=""
ssl_key=""
ssl_cipher_suite=""

# Rate limiting
ratelimit_enabled="0"
max_connections_per_ip="5"
burst_size="65535"
queue_size="524288"
client_timeout="30"
header_timeout="15"
source_timeout="10"

# Mount points storage
mounts=""

load_server() {
	config_get hostname "$1" hostname "$hostname"
	config_get port "$1" port "$port"
	config_get admin_user "$1" admin_user "$admin_user"
	config_get admin_password "$1" admin_password "$admin_password"
	config_get source_password "$1" source_password "$source_password"
	config_get relay_password "$1" relay_password "$relay_password"
	config_get max_listeners "$1" max_listeners "$max_listeners"
	config_get max_sources "$1" max_sources "$max_sources"
	config_get location "$1" location "$location"
	config_get admin_email "$1" admin_email "$admin_email"
}

load_paths() {
	config_get basedir "$1" basedir "$basedir"
	config_get logdir "$1" logdir "$logdir"
	config_get webroot "$1" webroot "$webroot"
	config_get adminroot "$1" adminroot "$adminroot"
}

load_logging() {
	config_get loglevel "$1" loglevel "$loglevel"
	config_get accesslog "$1" accesslog "$accesslog"
	config_get errorlog "$1" errorlog "$errorlog"
	config_get logsize "$1" logsize "$logsize"
	config_get logarchive "$1" logarchive "$logarchive"
}

load_security() {
	config_get chroot "$1" chroot "$chroot"
	config_get changeowner "$1" changeowner "$changeowner"
	config_get user "$1" user "$user"
	config_get group "$1" group "$group"
}

load_ssl() {
	config_get ssl_enabled "$1" enabled "$ssl_enabled"
	config_get ssl_port "$1" port "$ssl_port"
	config_get ssl_certificate "$1" certificate "$ssl_certificate"
	config_get ssl_key "$1" key "$ssl_key"
	config_get ssl_cipher_suite "$1" cipher_suite "$ssl_cipher_suite"
}

load_ratelimit() {
	config_get ratelimit_enabled "$1" enabled "$ratelimit_enabled"
	config_get max_connections_per_ip "$1" max_connections_per_ip "$max_connections_per_ip"
	config_get burst_size "$1" burst_size "$burst_size"
	config_get queue_size "$1" queue_size "$queue_size"
	config_get client_timeout "$1" client_timeout "$client_timeout"
	config_get header_timeout "$1" header_timeout "$header_timeout"
	config_get source_timeout "$1" source_timeout "$source_timeout"
}

load_mount() {
	local name type fallback_mount public max_listeners hidden genre description

	config_get name "$1" name ""
	[ -z "$name" ] && return

	config_get type "$1" type "normal"
	config_get fallback_mount "$1" fallback_mount ""
	config_get public "$1" public "0"
	config_get max_listeners "$1" max_listeners ""
	config_get hidden "$1" hidden "0"
	config_get genre "$1" genre ""
	config_get description "$1" description ""

	mounts="$mounts
    <mount type=\"$type\">
        <mount-name>$name</mount-name>"

	[ -n "$fallback_mount" ] && mounts="$mounts
        <fallback-mount>$fallback_mount</fallback-mount>
        <fallback-override>1</fallback-override>"

	[ "$public" = "1" ] && mounts="$mounts
        <public>1</public>"

	[ -n "$max_listeners" ] && [ "$max_listeners" != "0" ] && mounts="$mounts
        <max-listeners>$max_listeners</max-listeners>"

	[ "$hidden" = "1" ] && mounts="$mounts
        <hidden>1</hidden>"

	[ -n "$genre" ] && mounts="$mounts
        <genre>$genre</genre>"

	[ -n "$description" ] && mounts="$mounts
        <description>$description</description>"

	mounts="$mounts
    </mount>"
}

generate_config() {
	# Build SSL listen socket if enabled
	local ssl_socket=""
	if [ "$ssl_enabled" = "1" ] && [ -f "$ssl_certificate" ] && [ -f "$ssl_key" ]; then
		ssl_socket="
    <listen-socket>
        <port>$ssl_port</port>
        <ssl>1</ssl>
    </listen-socket>"
	fi

	# Build SSL paths if enabled
	local ssl_paths=""
	if [ "$ssl_enabled" = "1" ] && [ -f "$ssl_certificate" ] && [ -f "$ssl_key" ]; then
		ssl_paths="
        <ssl-certificate>$ssl_certificate</ssl-certificate>
        <ssl-private-key>$ssl_key</ssl-private-key>"
		[ -n "$ssl_cipher_suite" ] && ssl_paths="$ssl_paths
        <ssl-cipher-suite>$ssl_cipher_suite</ssl-cipher-suite>"
	fi

	cat > "$OUTPUT" << EOF
<!-- Icecast configuration - Auto-generated from UCI -->
<!-- Do not edit directly, use /etc/config/icecast -->
<icecast>
    <location>$location</location>
    <admin>$admin_email</admin>

    <limits>
        <clients>$max_listeners</clients>
        <sources>$max_sources</sources>
        <queue-size>$queue_size</queue-size>
        <client-timeout>$client_timeout</client-timeout>
        <header-timeout>$header_timeout</header-timeout>
        <source-timeout>$source_timeout</source-timeout>
        <burst-on-connect>1</burst-on-connect>
        <burst-size>$burst_size</burst-size>
    </limits>

    <authentication>
        <source-password>$source_password</source-password>
        <relay-password>$relay_password</relay-password>
        <admin-user>$admin_user</admin-user>
        <admin-password>$admin_password</admin-password>
    </authentication>

    <hostname>$hostname</hostname>

    <listen-socket>
        <port>$port</port>
    </listen-socket>
$ssl_socket

    <http-headers>
        <header name="Access-Control-Allow-Origin" value="*" />
        <header name="X-Content-Type-Options" value="nosniff" />
        <header name="X-Frame-Options" value="SAMEORIGIN" />
    </http-headers>
$mounts

    <fileserve>1</fileserve>

    <paths>
        <basedir>$basedir</basedir>
        <logdir>$logdir</logdir>
        <webroot>$webroot</webroot>
        <adminroot>$adminroot</adminroot>
        <pidfile>/var/run/icecast/icecast.pid</pidfile>$ssl_paths
    </paths>

    <logging>
        <accesslog>$accesslog</accesslog>
        <errorlog>$errorlog</errorlog>
        <loglevel>$loglevel</loglevel>
        <logsize>$logsize</logsize>
        <logarchive>$logarchive</logarchive>
    </logging>

    <security>
        <chroot>$chroot</chroot>
        <changeowner>
            <user>$user</user>
            <group>$group</group>
        </changeowner>
    </security>
</icecast>
EOF

	chmod 640 "$OUTPUT"
	chown root:icecast "$OUTPUT" 2>/dev/null

	echo "Generated $OUTPUT"
}

# Main
config_load "$CONFIG"

config_foreach load_server server
config_foreach load_paths paths
config_foreach load_logging logging
config_foreach load_security security
config_foreach load_ssl ssl
config_foreach load_ratelimit ratelimit
config_foreach load_mount mount

generate_config
