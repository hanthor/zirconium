FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install \
    gcc \
    git \
    make \
    cmake

WORKDIR /build

RUN git clone https://github.com/ndevilla/iniparser.git .

# Iniparser uses Make but lacks a good install target for distros in some versions.
# Checking recent version, it has CMake support.
RUN cmake -B build -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
RUN cmake --build build
RUN cmake --install build --prefix /install/usr

FROM scratch
COPY --from=builder /install /
