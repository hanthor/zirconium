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

# Clone libjxl - pinned to v0.11.1 for supply chain security
RUN git clone --recursive https://github.com/libjxl/libjxl.git . && \
    git checkout 794a5dcf0d54f9f0b20d288a12e87afb91d20dfc

RUN cmake -B build -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
RUN cmake --build build --config Release
RUN cmake --install build --config Release --prefix /install/usr

FROM scratch
COPY --from=builder /install /
