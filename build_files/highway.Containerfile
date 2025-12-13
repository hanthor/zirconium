FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install \
    cmake \
    gcc-c++ \
    git \
    make

WORKDIR /build

# renovate: datasource=git-refs depName=highway packageName=https://github.com/google/highway.git versioning=loose
RUN git clone https://github.com/google/highway.git . && \
    git checkout ff79fff5970e66526e37cfe9b920c2694dfb0f63

RUN cmake -B build -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DHWY_ENABLE_EXAMPLES=OFF -DHWY_ENABLE_TESTS=OFF
RUN cmake --build build
RUN cmake --install build --prefix /install/usr

FROM scratch
COPY --from=builder /install /
