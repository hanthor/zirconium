FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install \
    cmake \
    gcc \
    git \
    make

WORKDIR /build

RUN git clone https://github.com/JuliaStrings/utf8proc.git .

RUN cmake -B build -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
RUN cmake --build build
RUN cmake --install build --prefix /install/usr

FROM scratch
COPY --from=builder /install /
