FROM quay.io/centos/centos:stream10 AS builder

# Install build dependencies
RUN dnf -y install epel-release && \
    dnf -y --enablerepo=crb install \
    cargo \
    rust \
    git \
    gcc \
    clang \
    xcb-util-cursor-devel \
    libxcb-devel \
    pkgconf

WORKDIR /build

# clone xwayland-satellite
RUN git clone https://github.com/Supreeeme/xwayland-satellite.git .

# Build xwayland-satellite
RUN cargo build --release

# Copy artifacts to a clean layer
FROM scratch
COPY --from=builder /build/target/release/xwayland-satellite /usr/bin/xwayland-satellite
