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
    libxkbcommon-devel \
    scdoc \
    cmake \
    check-devel \
    systemd-devel

WORKDIR /build

# Build tllist
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
RUN git clone https://codeberg.org/dnkl/fcft.git && \
    cd fcft && \
    meson setup build --prefix=/usr -Ddocs=disabled && \
    ninja -C build && \
    ninja -C build install

# Build foot
WORKDIR /build/foot
RUN git clone https://codeberg.org/dnkl/foot.git .
RUN meson setup build --prefix=/usr -Ddocs=disabled -Dtests=disabled && ninja -C build
RUN DESTDIR=/install ninja -C build install

FROM scratch
COPY --from=builder /install /
