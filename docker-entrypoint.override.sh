#!/bin/sh
#set -e

function start_socat {
    rm -rf /proxy/*
    socat -d UNIX-LISTEN:/proxy/docker.sock,reuseaddr,fork TCP:localhost:2375
}


start_socat &

exec /docker-entrypoint.sh "$@"
