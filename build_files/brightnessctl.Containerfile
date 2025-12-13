FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install \
    gcc \
    git \
    make \
    systemd-devel

WORKDIR /build

RUN git clone https://github.com/Hummer12007/brightnessctl.git .

RUN ./configure --prefix=/usr
RUN make
RUN make install DESTDIR=/install

FROM scratch
COPY --from=builder /install /
