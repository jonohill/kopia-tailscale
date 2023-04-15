#!/usr/bin/env bash

set -e

# wait for certificate to be generated
while ! [ -f /config/server.cert ] || ! [ -f /config/server.key ]; do
    echo "Waiting for certificate to be generated..."
    sleep 3
done

cmd=()
if [ -f /tmp/cmd.run ]; then
    while IFS= read -r line; do
        cmd+=("$line")
    done </tmp/cmd.run
fi

kopia "${cmd[@]}"
