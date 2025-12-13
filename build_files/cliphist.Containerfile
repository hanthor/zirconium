FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install \
    golang \
    git \
    make

WORKDIR /build

# renovate: datasource=git-refs depName=cliphist packageName=https://github.com/sentriz/cliphist.git versioning=loose
RUN git clone https://github.com/sentriz/cliphist.git . && \
    git checkout efb61cb5b5a28d896c05a24ac83b9c39c96575f2
RUN go build -o cliphist .

FROM scratch
COPY --from=builder /build/cliphist /usr/bin/cliphist
