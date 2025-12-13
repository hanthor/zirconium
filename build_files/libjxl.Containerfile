FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install epel-release && \
    dnf -y --enablerepo=crb install \
    cmake \
    gcc-c++ \
    clang \
    git \
    pkgconf \
    brotli-devel \
    giflib-devel \
    libjpeg-turbo-devel \
    libpng-devel \
    libwebp-devel

WORKDIR /build

# renovate: datasource=git-refs depName=libjxl packageName=https://github.com/libjxl/libjxl.git versioning=loose
RUN git clone --recursive https://github.com/libjxl/libjxl.git . && \
    git checkout 53042ec537712e0df08709524f4df097d42174bc

RUN cmake -B build -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
RUN cmake --build build --config Release
RUN cmake --install build --config Release --prefix /install/usr

FROM scratch
COPY --from=builder /install /
