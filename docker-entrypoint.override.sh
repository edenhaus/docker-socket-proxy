#!/bin/sh
set -e

socat -d -d -d UNIX-LISTEN:${PROXIED-SOCKET},reuseaddr,fork TCP:localhost:${PORT} \
& \
exec /docker-entrypoint.sh "$@"
