# Docker Socket Proxy

[![build](https://github.com/edenhaus/docker-socket-proxy/workflows/build/badge.svg)](https://github.com/edenhaus/docker-socket-proxy/actions?query=workflow%3Abuild)
[![Docker Pulls](https://img.shields.io/docker/pulls/edenhaus/docker-socket-proxy)](https://hub.docker.com/r/edenhaus/docker-socket-proxy/)
![Analytics](https://ga-beacon.prasadt.com/UA-101760811-3/github/docker-socket-proxy?pink&useReferer)

> This fork provides the possibility to proxy the unix socket too.

## What?

This is a security-enhanced proxy for the Docker Socket.

## Why?

Giving access to your Docker socket could mean giving root access to your host,
or even to your whole swarm, but some services require hooking into that socket
to react to events, etc. Using this proxy lets you block anything you consider
those services should not do.

## How?

We use the official [alpine][]-based [haproxy][] image with a small
configuration file.

It blocks access to the Docker socket API according to the environment
variables you set. It returns a `HTTP 403 Forbidden` status for those dangerous
requests that should never happen.

To redirect the unix socket to TCP, we use socat.

## Security recommendations

- Never expose this container's port to a public network. Only to a Docker
  networks where only reside the proxy itself and the service that uses it.
- Revoke access to any API section that you consider your service should not
  need.
- This image does not include TLS support, just plain HTTP proxy to the host
  Docker Unix socket (which is not TLS protected even if you configured your
  host for TLS protection). This is by design because you are supposed to
  restrict access to it through Docker's built-in firewall.
- [Read the docs](#suppported-api-versions) for the API version you are using,
  and **know what you are doing**.

## Usage

1.  Run the API proxy (`--privileged` flag is required here because it connects with the docker socket, which is a privileged connection in some SELinux/AppArmor contexts and would get locked otherwise):

        $ docker container run \
            -d --privileged \
            --name dockerproxy \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v /tmp/test/:/proxy/ \
            -p 127.0.0.1:2375:2375 \
            edenhaus/docker-socket-proxy

2.  Connect your local docker client to that socket:

        $ export DOCKER_HOST=unix:///tmp/test/docker.sock

3.  You can see the docker version:

        $ docker version
        Client:
         Version:      17.03.1-ce
         API version:  1.27
         Go version:   go1.7.5
         Git commit:   c6d412e
         Built:        Mon Mar 27 17:14:43 2017
         OS/Arch:      linux/amd64

        Server:
         Version:      17.03.1-ce
         API version:  1.27 (minimum version 1.12)
         Go version:   go1.7.5
         Git commit:   c6d412e
         Built:        Mon Mar 27 17:14:43 2017
         OS/Arch:      linux/amd64
         Experimental: false

4.  You cannot see running containers:

        $ docker container ls
        Error response from daemon: <html><body><h1>403 Forbidden</h1>
        Request forbidden by administrative rules.
        </body></html>

The same will happen to any containers that use this proxy's `2375` port to
access the Docker socket API.

## Grant or revoke access to certain API sections

You grant and revoke access to certain features of the Docker API through
environment variables.

Normally the variables match the URL prefix (i.e. `AUTH` blocks access to
`/auth/*` parts of the API, etc.).

Possible values for these variables:

- `0` to **revoke** access.
- `1` to **grant** access.

### Access granted by default

These API sections are mostly harmless and almost required for any service that
uses the API, so they are granted by default.

- `EVENTS`
- `PING`
- `VERSION`

### Access revoked by default

#### Security-critical

These API sections are considered security-critical, and thus access is revoked
by default. Maximum caution when enabling these.

- `AUTH`
- `SECRETS`
- `POST` and `DELETE`: When disabled (default), only `GET` and `HEAD` operations are allowed, meaning
  any section of the API is read-only.

#### Not always needed

You will possibly need to grant access to some of these API sections, which are
not so extremely critical but can expose some information that your service
does not need.

| GET            | POST                  | DELETE              |
| :------------- | :-------------------- | :------------------ |
| `BUILD`        | `ALLOW_RESTARTS`      | `CONTAINERS_DELETE` |
| `COMMIT`       | `CONTAINERS_PRUNE`    | `IMAGES_DELETE`     |
| `CONFIGS`      | `CONTAINERS_CREATE`   | `NETWORKS_DELETE`   |
| `CONTAINERS`   | `CONTAINERS_RESIZE`   | `VOLUMES_DELETE`    |
| `DISTRIBUTION` | `CONTAINERS_START`    |                     |
| `EXEC`         | `CONTAINERS_UPDATE`   |                     |
| `IMAGES`       | `CONTAINERS_RENAME`   |                     |
| `INFO`         | `CONTAINERS_PAUSE`    |                     |
| `NETWORKS`     | `CONTAINERS_UNPAUSE`  |                     |
| `NODES`        | `CONTAINERS_ATTACH`   |                     |
| `PLUGINS`      | `CONTAINERS_WAIT`     |                     |
| `SERVICES`     | `CONTAINERS_EXEC`     |                     |
| `SESSION`      | `VOLUMES_CREATE`      |                     |
| `SWARM`        | `VOLUMES_PRUNE`       |                     |
| `SYSTEM`       | `NETWORKS_CREATE`     |                     |
| `TASKS`        | `NETWORKS_PRUNE`      |                     |
| `VOLUMES`      | `NETWORKS_CONNECT`    |                     |
|                | `NETWORKS_DISCONNECT` |                     |
|                | `IMAGES_CREATE`       |                     |
|                | `IMAGES_PRUNE`        |                     |

> To allow `DELETE` and `POST` methods, you must also to set `DELETE=1` and `POST=1`.

## Logging

You can set the logging level or severity level of the messages to be logged with the
environment variable `LOG_LEVEL`. Defaul value is info. Possible values are: debug,
info, notice, warning, err, crit, alert and emerg.

## Supported API versions

- [1.27](https://docs.docker.com/engine/api/v1.27/)
- [1.28](https://docs.docker.com/engine/api/v1.28/)
- [1.29](https://docs.docker.com/engine/api/v1.29/)
- [1.30](https://docs.docker.com/engine/api/v1.30/)
- [1.37](https://docs.docker.com/engine/api/v1.37/)

## Feedback

Please send any feedback (issues, questions) to the [issue tracker][].

[alpine]: https://alpinelinux.org/
[haproxy]: http://www.haproxy.org/
[issue tracker]: https://github.com/edenhaus/docker-socket-proxy/issues
