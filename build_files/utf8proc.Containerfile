FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install \
    cmake \
    gcc \
    git \
    make

WORKDIR /build

# renovate: datasource=git-refs depName=utf8proc packageName=https://github.com/JuliaStrings/utf8proc.git versioning=loose
RUN git clone https://github.com/JuliaStrings/utf8proc.git . && \
    git checkout 90daf9f396cfec91668758eb9cc54bd5248a6b89

RUN cmake -B build -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
RUN cmake --build build
RUN cmake --install build --prefix /install/usr

FROM scratch
COPY --from=builder /install /
