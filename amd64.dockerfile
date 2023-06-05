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
    go get -u all; \
    go build -o /usr/local/bin ./cmd/...; \
    go build -o /usr/local/bin ./plugin/...;


# :: Header
  FROM 11notes/alpine:stable
  COPY --from=build /usr/local/bin/ /usr/local/bin

# :: Run
  USER root

  # :: update image
    RUN set -ex; \
      apk update; \
      apk upgrade; \
      apk add --update --no-cache \
        openssh-keygen;

  # :: prepare image
    RUN set -ex; \
      mkdir -p /sshpiderd/etc; \
      mkdir -p /sshpiderd/var; \
      mkdir -p /etc/ssh;

  # :: copy root filesystem changes and add execution rights to init scripts
    COPY ./rootfs /
    RUN set -ex; \
      chmod +x -R /usr/local/bin;

  # :: change home path for existing user and set correct permission
    RUN set -ex; \
      usermod -d /sshpiperd docker; \
      chown -R 1000:1000 \
        /sshpiperd \
        /etc/ssh;

# :: Volumes
  VOLUME ["/sshpiderd/var"]

# :: Monitor
  HEALTHCHECK CMD /usr/local/bin/healthcheck.sh || exit 1

# :: Start
  USER docker
  ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]