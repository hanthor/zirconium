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
RUN git clone https://codeberg.org/dnkl/tllist.git && \
    cd tllist && \
    meson setup build --prefix=/usr && \
    ninja -C build install

# Build utf8proc
RUN git clone https://github.com/JuliaStrings/utf8proc.git && \
    cd utf8proc && \
    cmake -B build -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr && \
    cmake --build build && \
    cmake --install build

# Build fcft
RUN git clone https://codeberg.org/dnkl/fcft.git fcft
RUN cd fcft && meson setup build --prefix=/usr -Ddocs=disabled && ninja -C build
RUN cd fcft && DESTDIR=/install ninja -C build install

FROM scratch
COPY --from=builder /install /
