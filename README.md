![banner](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/banner/README.png)

# SSHPIPER
![size](https://img.shields.io/badge/image_size-96MB-green?color=%2338ad2d)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/markdown/transparent5x2px.png)![pulls](https://img.shields.io/docker/pulls/11notes/sshpiper?color=2b75d6)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/markdown/transparent5x2px.png)[<img src="https://img.shields.io/github/issues/11notes/docker-sshpiper?color=7842f5">](https://github.com/11notes/docker-sshpiper/issues)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/markdown/transparent5x2px.png)![swiss_made](https://img.shields.io/badge/Swiss_Made-FFFFFF?labelColor=FF0000&logo=data:image/svg%2bxml;base64,PHN2ZyB2ZXJzaW9uPSIxIiB3aWR0aD0iNTEyIiBoZWlnaHQ9IjUxMiIgdmlld0JveD0iMCAwIDMyIDMyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDxyZWN0IHdpZHRoPSIzMiIgaGVpZ2h0PSIzMiIgZmlsbD0idHJhbnNwYXJlbnQiLz4KICA8cGF0aCBkPSJtMTMgNmg2djdoN3Y2aC03djdoLTZ2LTdoLTd2LTZoN3oiIGZpbGw9IiNmZmYiLz4KPC9zdmc+)

Run sshpiper rootless and distroless.

# INTRODUCTION 📢

[sshpiper](https://github.com/tg123/sshpiper) (created by [sshpiper](https://github.com/tg123)) is the reverse proxy for sshd. all protocols, including ssh, scp, port forwarding, running on top of ssh are supported.

# SYNOPSIS 📖
**What can I do with this?** This image will run sshpiper [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) and [distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md), for maximum security and performance. In addition to being small and secure, it also offers two additional plugins (rest_auth and rest_challenge) which allow you to use any backend for authentication and challenges.

# UNIQUE VALUE PROPOSITION 💶
**Why should I run this image and not the other image(s) that already exist?** Good question! Because ...

> [!IMPORTANT]
>* ... this image runs [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) as 1000:1000
>* ... this image has no shell since it is [distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md)
>* ... this image is auto updated to the latest version via CI/CD
>* ... this image has a health check
>* ... this image runs read-only
>* ... this image is automatically scanned for CVEs before and after publishing
>* ... this image is created via a secure and pinned CI/CD process
>* ... this image is very small

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

# VOLUMES 📁
* **//var** - Directory for screen recordings and other stuff (if used)

# COMPOSE ✂️
```yaml
name: "ssh"

x-lockdown: &lockdown
  # prevents write access to the image itself
  read_only: true
  # prevents any process within the container to gain more privileges
  security_opt:
    - "no-new-privileges=true"

services:
  socket-proxy:
    # for more information about this image checkout:
    # https://github.com/11notes/docker-socket-proxy
    image: "11notes/socket-proxy:2.1.6"
    <<: *lockdown
    user: "0:103"
    environment:
      TZ: "Europe/Zurich"
    volumes:
      - "/run/docker.sock:/run/docker.sock:ro" 
      - "socket-proxy.run:/run/proxy"
    restart: "always"

  sshpiper:
    depends_on:
      socket-proxy:
        condition: "service_healthy"
        restart: true
    image: "11notes/sshpiper:1.5.0"
    <<: *lockdown
    environment:
      TZ: "Europe/Zurich"
    command:
      - "docker"
      - "--"
      - "failtoban"
      - "--max-failures=3"
      - "--ban-duration=6h"
      # if using failtoban, ignore localhost or the healtcheck will be banned!
      - "--ignore-ip=127.0.0.1"
    ports:
      - "8022:22/tcp"
    volumes:
      - "socket-proxy.run:/var/run"
    networks:
      frontend:
      backend:
    secrets:
      - "ssh_host_key"
    sysctls:
      # allow rootless container to access ports < 1024
      net.ipv4.ip_unprivileged_port_start: 22
    restart: "always"

  sftp:
    # for more information about this image checkout:
    # https://github.com/11notes/docker-sftp
    image: "11notes/sftp:10.2"
    <<: *lockdown
    labels:
      - "sshpiper.username=foo"
    environment:
      TZ: "Europe/Zurich"
      SSH_USER: "foo"
      SSH_PASSWORD: "${SSH_PASSWORD}"
    volumes:
      - "foo.var:/home"
    tmpfs:
      - "/run/ssh:uid=1000,gid=1000,size=1m"
    secrets:
      - "ssh_host_key"
    networks:
      backend:
    sysctls:
      net.ipv4.ip_unprivileged_port_start: 22
    restart: "always"

  sftp-key:
    # for more information about this image checkout:
    # https://github.com/11notes/docker-sftp
    image: "11notes/sftp:10.2"
    <<: *lockdown
    labels:
      - "sshpiper.authorized_keys=${SFTP_AUTHORIZED_KEY}"
      - "sshpiper.private_key=${SFTP_PRIVATE_KEY}"
    environment:
      TZ: "Europe/Zurich"
      SSH_USER: "bar"
    volumes:
      - "bar.var:/home"
    tmpfs:
      - "/run/ssh:uid=1000,gid=1000,size=1m"
    secrets:
      - "ssh_host_key"
      - "authorized_keys"
    networks:
      backend:
    sysctls:
      net.ipv4.ip_unprivileged_port_start: 22
    restart: "always"

volumes:
  socket-proxy.run:
  sshpiper.var:
  foo.var:
  bar.var:

networks:
  frontend:
  backend:
    internal: true

secrets:
  ssh_host_key:
    file: "./ssh_host_ed25519_key.txt"
  authorized_keys:
    file: "./authorized_keys.txt"
```
To find out how you can change the default UID/GID of this container image, consult the [RTFM](https://github.com/11notes/RTFM/blob/main/linux/container/image/11notes/how-to.changeUIDGID.md#change-uidgid-the-correct-way).

# DEFAULT SETTINGS 🗃️
| Parameter | Value | Description |
| --- | --- | --- |
| `user` | docker | user name |
| `uid` | 1000 | [user identifier](https://en.wikipedia.org/wiki/User_identifier) |
| `gid` | 1000 | [group identifier](https://en.wikipedia.org/wiki/Group_identifier) |
| `home` | / | home directory of user docker |
| `--server-key` | /run/secrets/ssh_host_key | SSH host key |
| `--log-format` | json | json output to console |
| `--log-level` | info | log verbosity level |
| `--drop-hostkeys-message` |  | filter out hostkeys-00@openssh.com |
| `--reply-ping` |  | reply to ping@openssh instead of passing it to upstream |

# ENVIRONMENT 📝
| Parameter | Value | Default |
| --- | --- | --- |
| `TZ` | [Time Zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) | |
| `DEBUG` | Will activate debug option for container image and app (if available) | |

# MAIN TAGS 🏷️
These are the main tags for the image. There is also a tag for each commit and its shorthand sha256 value.

* [1.5.0](https://hub.docker.com/r/11notes/sshpiper/tags?name=1.5.0)

### There is no latest tag, what am I supposed to do about updates?
It is my opinion that the ```:latest``` tag is a bad habbit and should not be used at all. Many developers introduce **breaking changes** in new releases. This would messed up everything for people who use ```:latest```. If you don’t want to change the tag to the latest [semver](https://semver.org/), simply use the short versions of [semver](https://semver.org/). Instead of using ```:1.5.0``` you can use ```:1``` or ```:1.5```. Since on each new version these tags are updated to the latest version of the software, using them is identical to using ```:latest``` but at least fixed to a major or minor version. Which in theory should not introduce breaking changes.

If you still insist on having the bleeding edge release of this app, simply use the ```:rolling``` tag, but be warned! You will get the latest version of the app instantly, regardless of breaking changes or security issues or what so ever. You do this at your own risk!

# REGISTRIES ☁️
```
docker pull 11notes/sshpiper:1.5.0
docker pull ghcr.io/11notes/sshpiper:1.5.0
docker pull quay.io/11notes/sshpiper:1.5.0
```

# SOURCE 💾
* [11notes/sshpiper](https://github.com/11notes/docker-sshpiper)

# PARENT IMAGE 🏛️
> [!IMPORTANT]
>This image is not based on another image but uses [scratch](https://hub.docker.com/_/scratch) as the starting layer.
>The image consists of the following distroless layers that were added:
>* [11notes/distroless](https://github.com/11notes/docker-distroless/blob/master/arch.dockerfile) - contains users, timezones and Root CA certificates, nothing else
>* 11notes/distroless:nc

# BUILT WITH 🧰
* [tg123/sshpiper](https://github.com/tg123/sshpiper)

# GENERAL TIPS 📌
> [!TIP]
>* Use a reverse proxy like Traefik, Nginx, HAproxy to terminate TLS and to protect your endpoints
>* Use Let’s Encrypt DNS-01 challenge to obtain valid SSL certificates for your services

# ElevenNotes™️
This image is provided to you at your own risk. Always make backups before updating an image to a different version. Check the [releases](https://github.com/11notes/docker-sshpiper/releases) for breaking changes. If you have any problems with using this image simply raise an [issue](https://github.com/11notes/docker-sshpiper/issues), thanks. If you have a question or inputs please create a new [discussion](https://github.com/11notes/docker-sshpiper/discussions) instead of an issue. You can find all my other repositories on [github](https://github.com/11notes?tab=repositories).

*created 03.11.2025, 22:16:03 (CET)*