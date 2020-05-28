#!/bin/sh
#set -e

function start_socat {
    rm -rf /proxy/*
    sleep 5 #wait until haproxy is started
    socat -d UNIX-LISTEN:/proxy/docker.sock,reuseaddr,fork TCP:localhost:2375
}


start_socat &

exec /docker-entrypoint.sh "$@"