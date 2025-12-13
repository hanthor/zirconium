FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install \
    golang \
    git \
    make

WORKDIR /build

# Clone dgop - pinned to v0.1.11 for supply chain security
RUN git clone https://github.com/AvengeMedia/dgop.git . && \
    git checkout 6cf638dde818f9f8a2e26d0243179c43cb3458d7

RUN go build -o dgop ./cmd/cli

FROM scratch
COPY --from=builder /build/dgop /usr/bin/dgop
