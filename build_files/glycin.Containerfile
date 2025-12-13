FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install epel-release && \
    dnf -y --enablerepo=crb install \
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
    libheif-devel \
    librsvg2-devel \
    gobject-introspection-devel \
    vala \
    pkgconf

WORKDIR /build

RUN git clone https://gitlab.gnome.org/GNOME/glycin.git .

RUN meson setup build --prefix=/usr -Dloaders=glycin-heif,glycin-image-rs,glycin-svg && ninja -C build
RUN DESTDIR=/install ninja -C build install

FROM scratch
COPY --from=builder /install /
