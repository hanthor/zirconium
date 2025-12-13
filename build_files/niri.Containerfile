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

# clone niri - pinned to v25.11 for supply chain security
RUN git clone https://github.com/YaLTeR/niri.git . && \
    git checkout 15c52bfb4318f3b2452f511d5367b4bfe6335242

# Build niri
RUN cargo build --release

# Copy artifacts to a clean layer
FROM scratch
COPY --from=builder /build/target/release/niri /usr/bin/niri
