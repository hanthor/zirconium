FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install \
    cmake \
    gcc-c++ \
    git \
    qt6-qtbase-devel \
    qt6-qtdeclarative-devel \
    qt6-qtwayland-devel \
    qt6-qtshadertools-devel \
    pkgconf

WORKDIR /build

RUN git clone --recursive https://git.outfoxxed.me/quickshell/quickshell.git .

RUN cmake -B build -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
RUN cmake --build build
RUN cmake --install build --prefix /install/usr

FROM scratch
COPY --from=builder /install /
