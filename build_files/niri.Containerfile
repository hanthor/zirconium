FROM quay.io/centos/centos:stream10 AS builder

# Install build dependencies
RUN dnf -y install \
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
    glib2-devel \
    seatd-devel \
    libinput-devel \
    libgudev-devel \
    pkgconf

WORKDIR /build

# clone niri
RUN git clone https://github.com/YaLTeR/niri.git .

# Build niri
RUN cargo build --release

# Copy artifacts to a clean layer
FROM scratch
COPY --from=builder /build/target/release/niri /usr/bin/niri
