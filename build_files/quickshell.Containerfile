FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install epel-release && \
    dnf -y --enablerepo=crb install \
    cli11-devel \
    cmake \
    gcc-c++ \
    git \
    qt6-qtbase-devel \
    qt6-qtbase-private-devel \
    qt6-qtdeclarative-devel \
    qt6-qtwayland-devel \
    qt6-qtshadertools-devel \
    wayland-protocols-devel \
    libdrm-devel \
    mesa-libgbm-devel \
    pipewire-devel \
    glib2-devel \
    polkit-devel \
    jemalloc-devel \
    pam-devel \
    spirv-tools \
    wayland-devel \
    pkgconf

WORKDIR /build

RUN git clone --recursive https://git.outfoxxed.me/quickshell/quickshell.git .

RUN cmake -B build -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DCRASH_REPORTER=OFF
RUN cmake --build build
RUN cmake --install build --prefix /install/usr

FROM scratch
COPY --from=builder /install /
