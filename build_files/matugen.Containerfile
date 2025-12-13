FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install \
    cargo \
    rust \
    git \
    gcc \
    openssl-devel

WORKDIR /build

# renovate: datasource=git-refs depName=matugen packageName=https://github.com/InioX/matugen.git versioning=loose
RUN git clone https://github.com/InioX/matugen.git . && \
    git checkout de6381b5288c53763ba7c055661dc08ee8f107fa
RUN cargo build --release

FROM scratch
COPY --from=builder /build/target/release/matugen /usr/bin/matugen
