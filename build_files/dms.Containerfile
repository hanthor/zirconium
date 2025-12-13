FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install \
    golang \
    git \
    make

WORKDIR /build

RUN git clone https://github.com/AvengeMedia/DankMaterialShell.git .

# Build Core CLI
WORKDIR /build/core
RUN make

# Copy artifacts
FROM scratch
COPY --from=builder /build/core/dms /usr/bin/dms
# Copy the shell and greeter assets
COPY --from=builder /build/quickshell /usr/share/dms/shell
COPY --from=builder /build/greeter /usr/share/dms/greeter
