FROM quay.io/centos/centos:stream10 AS builder

# Install build dependencies
RUN dnf -y install epel-release && \
    dnf -y --enablerepo=crb install \
    cargo \
    rust \
    clang \
    git \
    make \
    systemd-devel \
    wayland-devel \
    mesa-libgbm-devel \
    libxkbcommon-devel \
    pango-devel \
    cairo-devel \
    cairo-gobject-devel \
    glib2-devel \
    libseat-devel \
    libdisplay-info-devel \
    pipewire-devel \
    libinput-devel \
    libgudev-devel \
    pkgconf

WORKDIR /build

# clone niri
# renovate: datasource=git-refs depName=niri packageName=https://github.com/YaLTeR/niri.git versioning=loose
RUN git clone https://github.com/YaLTeR/niri.git . && \
    git checkout d1fc1ab731f7cc59923a16acce9a387782bfeb10

# Build niri
RUN cargo build --release

# Copy artifacts to a clean layer
FROM scratch
COPY --from=builder /build/target/release/niri /usr/bin/niri
COPY --from=builder /build/resources/niri.service /usr/lib/systemd/user/niri.service
COPY --from=builder /build/resources/niri-session /usr/bin/niri-session
