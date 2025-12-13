FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install \
    golang \
    git \
    make \
    gcc

WORKDIR /build

# renovate: datasource=git-refs depName=dms packageName=https://github.com/AvengeMedia/DankMaterialShell.git versioning=loose
RUN git clone https://github.com/AvengeMedia/DankMaterialShell.git . && \
    git checkout e4e20fb43a4627ab6d1581b14d6f7b5dab7d0820

# Build Core CLI
WORKDIR /build/core
RUN go build -o dms ./cmd/dms

# Copy artifacts
FROM scratch
COPY --from=builder /build/core/dms /usr/bin/dms
# Copy the shell and greeter assets
COPY --from=builder /build/quickshell /usr/share/dms/shell
COPY --from=builder /build/quickshell/Modules/Greetd /usr/share/dms/greeter
