FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install \
    cargo \
    rust \
    git \
    gcc \
    openssl-devel

WORKDIR /build

RUN git clone https://github.com/InioX/matugen.git .
RUN cargo build --release

FROM scratch
COPY --from=builder /build/target/release/matugen /usr/bin/matugen
