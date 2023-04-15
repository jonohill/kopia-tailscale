#!/usr/bin/env bash

set -e

up() {

    echo "Waiting for tailscaled to start"
    while ! [ -S /var/run/tailscale/tailscaled.sock ]; do
        sleep 1
    done

    tailscale up \
        --auth-key="$TS_AUTH_KEY" \
        --hostname="$TS_HOSTNAME"

    # output looks like e.g. `For domain, use "kopia.some-thing.ts.net".`
    TS_DOMAIN="$(tailscale cert 2>&1 | grep "ts.net" | sed -E 's/.*"(.*\.ts\.net)".*/\1/')"
    
    tailscale cert \
        --cert-file /config/server.cert \
        --key-file /config/server.key \
        "$TS_DOMAIN"
}

up &

exec tailscaled \
    -tun=userspace-networking
