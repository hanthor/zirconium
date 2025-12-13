FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install \
    golang \
    git \
    make \
    gcc

WORKDIR /build

# Clone DMS - pinned to v1.0.2 for supply chain security
RUN git clone https://github.com/AvengeMedia/DankMaterialShell.git . && \
    git checkout fe3163d02fe118e83b480efb9bed0127e7d83382

# Build Core CLI
WORKDIR /build/core
RUN go build -o dms ./cmd/dms

# Copy artifacts
FROM scratch
COPY --from=builder /build/core/dms /usr/bin/dms
# Copy the shell and greeter assets
COPY --from=builder /build/quickshell /usr/share/dms/shell
COPY --from=builder /build/quickshell/Modules/Greetd /usr/share/dms/greeter
