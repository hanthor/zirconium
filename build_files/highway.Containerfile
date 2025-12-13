FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install \
    cmake \
    gcc-c++ \
    git \
    make

WORKDIR /build

RUN git clone https://github.com/google/highway.git .

RUN cmake -B build -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DHWY_ENABLE_EXAMPLES=OFF -DHWY_ENABLE_TESTS=OFF
RUN cmake --build build
RUN cmake --install build --prefix /install/usr

FROM scratch
COPY --from=builder /install /
