FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install \
    golang \
    git \
    make

WORKDIR /build

RUN git clone https://github.com/sentriz/cliphist.git .
RUN go build -o cliphist .

FROM scratch
COPY --from=builder /build/cliphist /usr/bin/cliphist
