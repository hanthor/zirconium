FROM quay.io/centos/centos:stream10 AS builder

# Install build dependencies
RUN dnf -y install epel-release && \
    dnf -y --enablerepo=crb install \
    cargo \
    rust \
    git \
    gcc \
    pkgconf

WORKDIR /build

# renovate: datasource=git-refs depName=tuigreet packageName=https://github.com/apognu/tuigreet.git versioning=loose
RUN git clone https://github.com/apognu/tuigreet.git . && \
    git checkout 2aeca1b63dec977fc4e2ac6f97432386bedbc546

# Build tuigreet
RUN cargo build --release

# Copy artifacts to a clean layer
FROM scratch
COPY --from=builder /build/target/release/tuigreet /usr/bin/tuigreet
