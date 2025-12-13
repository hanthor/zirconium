FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install \
    golang \
    git \
    make

WORKDIR /build

# renovate: datasource=git-refs depName=dgop packageName=https://github.com/AvengeMedia/dgop.git versioning=loose
RUN git clone https://github.com/AvengeMedia/dgop.git . && \
    git checkout 57279532bc932b93df79d866b0663b1753cefda1
RUN go build -o dgop ./cmd/cli

FROM scratch
COPY --from=builder /build/dgop /usr/bin/dgop
