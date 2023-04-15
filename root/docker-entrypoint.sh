#!/usr/bin/env bash

set -e

mkdir -p /config /data

cmd=(
    server start
    --address http://0.0.0.0:443
    --tls-cert-file /config/server.cert
    --tls-key-file /config/server.key
)

if [ -n "$1" ]; then
    cmd=("$@")
fi

printf '' >/tmp/cmd.run
for x in "${cmd[@]}"; do
    echo "$x" >>/tmp/cmd.run
done

exec multirun /etc/multirun/*.sh
