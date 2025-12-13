FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install \
    cargo \
    rust \
    git \
    meson \
    ninja-build \
    gcc \
    clang \
    gtk4-devel \
    libseccomp-devel \
    lcms2-devel \
    pkgconf

WORKDIR /build

RUN git clone https://gitlab.gnome.org/GNOME/glycin.git .

RUN meson setup build --prefix=/usr && ninja -C build
RUN DESTDIR=/install ninja -C build install

FROM scratch
COPY --from=builder /install /
