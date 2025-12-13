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

# renovate: datasource=git-refs depName=glycin packageName=https://gitlab.gnome.org/GNOME/glycin.git versioning=loose
RUN git clone https://gitlab.gnome.org/GNOME/glycin.git . && \
    git checkout 0865d33a7870a1cb8bf35c89f75d2cfab4129ee8

RUN meson setup build --prefix=/usr -Dloaders=glycin-heif,glycin-image-rs,glycin-svg && ninja -C build
RUN DESTDIR=/install ninja -C build install

FROM scratch
COPY --from=builder /install /
