FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install \
    git \
    meson \
    ninja-build \
    gcc \
    wayland-devel \
    wayland-protocols-devel \
    scdoc

WORKDIR /build

RUN git clone https://github.com/kennylevinsen/wlsunset.git .
RUN meson setup build && ninja -C build

FROM scratch
COPY --from=builder /build/build/wlsunset /usr/bin/wlsunset
