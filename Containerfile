ARG BUILD_FLAVOR="${BUILD_FLAVOR:-}"
ARG REPOSITORY="${REPOSITORY:-ghcr.io/hanthor}"

FROM scratch AS ctx

COPY build_files /build
COPY system_files /files
COPY cosign.pub /files/etc/pki/containers/zirconium.pub

FROM ${REPOSITORY}/niri:latest AS niri
FROM ${REPOSITORY}/dms:latest AS dms
FROM ${REPOSITORY}/dgop:latest AS dgop
FROM ${REPOSITORY}/cliphist:latest AS cliphist
FROM ${REPOSITORY}/matugen:latest AS matugen
FROM ${REPOSITORY}/wlsunset:latest AS wlsunset
FROM ${REPOSITORY}/glycin:latest AS glycin
FROM ${REPOSITORY}/libjxl:latest AS libjxl
FROM ${REPOSITORY}/quickshell:latest AS quickshell
FROM ${REPOSITORY}/tuigreet:latest AS tuigreet
FROM ${REPOSITORY}/xwayland-satellite:latest AS xwayland-satellite
FROM ${REPOSITORY}/greetd:latest AS greetd

FROM quay.io/centos-bootc/centos-bootc:stream10
ARG BUILD_FLAVOR="${BUILD_FLAVOR:-}"

# Copy OCI Artifacts
COPY --from=niri /usr/bin/niri /usr/bin/niri
COPY --from=dms / /
COPY --from=dgop /usr/bin/dgop /usr/bin/dgop
COPY --from=cliphist /usr/bin/cliphist /usr/bin/cliphist
COPY --from=matugen /usr/bin/matugen /usr/bin/matugen
COPY --from=wlsunset /usr/bin/wlsunset /usr/bin/wlsunset
COPY --from=glycin / /
COPY --from=libjxl / /
COPY --from=quickshell / /
COPY --from=tuigreet /usr/bin/tuigreet /usr/bin/tuigreet
COPY --from=xwayland-satellite /usr/bin/xwayland-satellite /usr/bin/xwayland-satellite
COPY --from=greetd / /
ARG BUILD_FLAVOR="${BUILD_FLAVOR:-}"

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/var \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build/00-base.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/var \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build/01-theme.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/var \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build/02-extras.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build/03-nvidia.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build/99-cleanup.sh

# This is handy for VM testing
# RUN usermod -p "$(echo "changeme" | mkpasswd -s)" root

RUN rm -rf /var/* && bootc container lint
