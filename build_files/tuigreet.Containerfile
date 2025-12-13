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

# clone tuigreet
RUN git clone https://github.com/apognu/tuigreet.git .

# Build tuigreet
RUN cargo build --release

# Copy artifacts to a clean layer
FROM scratch
COPY --from=builder /build/target/release/tuigreet /usr/bin/tuigreet
