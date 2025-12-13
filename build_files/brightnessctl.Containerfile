FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install \
    gcc \
    git \
    make \
    systemd-devel

WORKDIR /build

# renovate: datasource=git-refs depName=brightnessctl packageName=https://github.com/Hummer12007/brightnessctl.git versioning=loose
RUN git clone https://github.com/Hummer12007/brightnessctl.git . && \
    git checkout e70bc55cf053caa285695ac77507e009b5508ee3

RUN ./configure --prefix=/usr
RUN make
RUN make install DESTDIR=/install

FROM scratch
COPY --from=builder /install /
