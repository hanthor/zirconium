FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install \
    golang \
    git \
    make

WORKDIR /build

# Clone cliphist - pinned to v0.7.0 for supply chain security
RUN git clone https://github.com/sentriz/cliphist.git . && \
    git checkout efb61cb5b5a28d896c05a24ac83b9c39c96575f2

RUN go build -o cliphist .

FROM scratch
COPY --from=builder /build/cliphist /usr/bin/cliphist
