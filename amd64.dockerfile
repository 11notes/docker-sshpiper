# :: Builder
    FROM golang:alpine as sshpiper
    ENV checkout=v1.0.62

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
        sed -i "s/\/\/go:build full || e2e//g" /go/sshpiper/plugin/yaml/yaml.go; \
        sed -i "s/\/\/go:build full || e2e//g" /go/sshpiper/plugin/yaml/main.go; \
        go build -o /usr/local/bin ./cmd/...; \
        go build -o /usr/local/bin ./plugin/...;
        

# :: Header
    FROM alpine:latest
    ENV LANG C.UTF-8
    ENV LC_ALL C.UTF-8
    ENV FORCE_COLOR 1
    COPY --from=sshpiper /usr/local/bin/ /usr/local/bin

# :: Run
    USER root

    # :: prepare
        RUN set -ex; \
            apk add --update --no-cache \
                curl \
                shadow \
                openssh-keygen; \
            mkdir -p /sshpiderd/etc; \
            mkdir -p /sshpiderd/var; \
            mkdir -p /etc/ssh;

        RUN set -ex; \
			addgroup --gid 1000 -S sshpiperd; \
			adduser --uid 1000 -D -S -h /sshpiperd -s /sbin/nologin -G sshpiperd sshpiperd;

    # :: add rootfs
        COPY ./rootfs /

    # :: docker -u 1000:1000 (no root initiative)
        RUN chown -R sshpiperd:sshpiperd \
            /sshpiperd;

# :: Volumes
	VOLUME ["/sshpiderd/var"]

# :: Monitor
    RUN chmod +x /usr/local/bin/healthcheck.sh
    HEALTHCHECK CMD /usr/local/bin/healthcheck.sh || exit 1

# :: Start
    RUN chmod +x /usr/local/bin/entrypoint.sh
    USER sshpiperd
    ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]