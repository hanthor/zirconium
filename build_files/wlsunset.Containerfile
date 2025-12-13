FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install epel-release && \
    dnf -y --enablerepo=crb install \
    git \
    meson \
    ninja-build \
    gcc \
    wayland-devel \
    wayland-protocols-devel \
    scdoc

WORKDIR /build

# renovate: datasource=git-refs depName=wlsunset packageName=https://github.com/kennylevinsen/wlsunset.git versioning=loose
RUN git clone https://github.com/kennylevinsen/wlsunset.git . && \
    git checkout f7e4d0b5fd5f57ee1cc0d6fe2f7547eca3a47c14
RUN meson setup build && ninja -C build

FROM scratch
COPY --from=builder /build/build/wlsunset /usr/bin/wlsunset
