FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install \
    cargo \
    rust \
    git \
    gcc \
    openssl-devel

WORKDIR /build

# Clone matugen - pinned to v3.1.0 for supply chain security
RUN git clone https://github.com/InioX/matugen.git . && \
    git checkout 7375b9c5514140f8c551798ab78df687b6f396df

RUN cargo build --release

FROM scratch
COPY --from=builder /build/target/release/matugen /usr/bin/matugen
