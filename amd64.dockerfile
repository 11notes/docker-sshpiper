# :: Builder
  FROM golang:alpine as build
  ENV checkout=v1.0.105

  RUN set -ex; \
    apk add --update --no-cache \
      curl \
      git; \
    git clone https://github.com/tg123/sshpiper.git; \
    cd /go/sshpiper; \
    git checkout ${checkout}; \
    git submodule update --init --recursive;

  COPY ./build /go/sshpiper

  RUN set -ex; \
    cd /go/sshpiper; \
    go get github.com/fatih/color; \
    rm -rf /go/sshpiper/plugin/kubernetes; \
    rm -rf /go/sshpiper/plugin/workingdir; \
    go build -o /usr/local/bin ./cmd/...; \
    go build -o /usr/local/bin ./plugin/...;


# :: Header
  FROM 11notes/alpine:stable
  ENV LANG C.UTF-8
  ENV LC_ALL C.UTF-8
  ENV FORCE_COLOR 1
  COPY --from=build /usr/local/bin/ /usr/local/bin

# :: Run
  USER root

  # :: prepare
  RUN set -ex; \
    apk add --update --no-cache \
      curl \
      openssh-keygen; \
    apk upgrade; \
    mkdir -p /sshpiderd/etc; \
    mkdir -p /sshpiderd/var; \
    mkdir -p /etc/ssh;

  RUN set -ex; \
    addgroup --gid 1000 -S sshpiperd; \
    adduser --uid 1000 -D -S -h /sshpiperd -s /sbin/nologin -G sshpiperd sshpiperd;

  # :: copy root filesystem changes
    COPY ./rootfs /
    RUN set -ex; \
      chmod +x -R /usr/local/bin

  # :: docker -u 1000:1000 (no root initiative)
    RUN set -ex; \
      chown -R sshpiperd:sshpiperd \
        /sshpiperd \
        /etc/ssh;

# :: Volumes
  VOLUME ["/sshpiderd/var"]

# :: Monitor
  HEALTHCHECK CMD /usr/local/bin/healthcheck.sh || exit 1

# :: Start
  USER sshpiperd
  ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]