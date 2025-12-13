FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install epel-release && \
    dnf -y --enablerepo=crb install \
    meson \
    ninja-build \
    gcc \
    git \
    fontconfig-devel \
    freetype-devel \
    pixman-devel \
    harfbuzz-devel \
    libpng-devel \
    wayland-devel \
    wayland-protocols-devel \
    scdoc \
    cmake \
    check-devel

WORKDIR /build

# Build tllist (header only)
# renovate: datasource=git-refs depName=tllist packageName=https://codeberg.org/dnkl/tllist.git versioning=loose
RUN git clone https://codeberg.org/dnkl/tllist.git && \
    cd tllist && \
    git checkout 05b463da2ee4a81903126756689282f99f88cc30 && \
    meson setup build --prefix=/usr && \
    ninja -C build install

# Build utf8proc
# renovate: datasource=git-refs depName=utf8proc packageName=https://github.com/JuliaStrings/utf8proc.git versioning=loose
RUN git clone https://github.com/JuliaStrings/utf8proc.git && \
    cd utf8proc && \
    git checkout 90daf9f396cfec91668758eb9cc54bd5248a6b89 && \
    cmake -B build -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr && \
    cmake --build build && \
    cmake --install build

# Build fcft
# renovate: datasource=git-refs depName=fcft packageName=https://codeberg.org/dnkl/fcft.git versioning=loose
RUN git clone https://codeberg.org/dnkl/fcft.git fcft && \
    cd fcft && \
    git checkout a78682f28e67ff31177aa218224501b28a0d4c79
RUN cd fcft && meson setup build --prefix=/usr -Ddocs=disabled && ninja -C build
RUN cd fcft && DESTDIR=/install ninja -C build install

FROM scratch
COPY --from=builder /install /
