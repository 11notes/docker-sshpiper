# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      BUILD_ROOT=/go/sshpiper \
      BUILD_SRC=tg123/sshpiper.git

# :: FOREIGN IMAGES
  FROM 11notes/distroless AS distroless
  FROM 11notes/distroless:nc AS distroless-nc

# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: SSHPIPER
  FROM 11notes/go:1.25 AS build
  ARG APP_VERSION \
      BUILD_ROOT \
      BUILD_SRC

  RUN set -ex; \
    eleven git clone ${BUILD_SRC} v${APP_VERSION};

  COPY ./build/go/sshpiper /go/sshpiper

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    mkdir -p /tmp/sshpiper; \
    rm -rf ./plugin/simplemath; \
    go mod tidy; \
    go build -tags full -ldflags="-extldflags=-static -X main.mainver=${APP_VERSION}" -o /tmp/sshpiper ./cmd/...; \
    go build -tags full -ldflags="-extldflags=-static" -o /tmp/sshpiper ./plugin/...;

  RUN set -ex; \
    cd /tmp/sshpiper; \
    for BIN in *; do \
      eleven distroless ${BIN}; \
    done;

# :: ENTRYPOINT
  FROM 11notes/go:1.25 AS entrypoint
  COPY ./build /
  RUN set -ex; \
    cd /go/entrypoint; \
    eleven go build /entrypoint main.go; \
    eleven distroless /entrypoint;

# :: FILE SYSTEM
  FROM alpine AS file-system
  ARG APP_ROOT

  RUN set -ex; \
    mkdir -p /distroless${APP_ROOT}/var;

# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
# :: HEADER
  FROM scratch

  # :: default arguments
    ARG TARGETPLATFORM \
        TARGETOS \
        TARGETARCH \
        TARGETVARIANT \
        APP_IMAGE \
        APP_NAME \
        APP_VERSION \
        APP_ROOT \
        APP_UID \
        APP_GID \
        APP_NO_CACHE

  # :: default environment
    ENV APP_IMAGE=${APP_IMAGE} \
        APP_NAME=${APP_NAME} \
        APP_VERSION=${APP_VERSION} \
        APP_ROOT=${APP_ROOT}

  # :: multi-stage
    COPY --from=distroless / /
    COPY --from=distroless-nc / /
    COPY --from=build /distroless/ /
    COPY --from=entrypoint /distroless/ /
    COPY --from=file-system --chown=${APP_UID}:${APP_GID} /distroless/ /

# :: PERSISTENT DATA
  VOLUME ["${APP_ROOT}/var"]

# :: MONITORING
  HEALTHCHECK --interval=5s --timeout=2s --start-period=5s \
    CMD ["/usr/local/bin/nc", "-z", "127.0.0.1", "22"]

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/entrypoint"]