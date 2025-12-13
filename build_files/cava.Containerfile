FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install epel-release && \
    dnf -y --enablerepo=crb install \
    autoconf \
    automake \
    libtool \
    gcc \
    git \
    make \
    fftw-devel \
    ncurses-devel \
    pulseaudio-libs-devel \
    pipewire-devel \
    alsa-lib-devel \
    iniparser-devel \
    SDL2-devel

# Note: iniparser-devel might not be available or too old.
# We will clone and build iniparser if needed, but defining it here just in case.
# Cava usually includes iniparser as submodule or lets you use system.
# Let's check cava repo logic.
# Cava repo has iniparser as dependency (vendored or system).
# If building from source: ./autogen.sh && ./configure && make

WORKDIR /build

# renovate: datasource=git-refs depName=cava packageName=https://github.com/karlstav/cava.git versioning=loose
RUN git clone https://github.com/karlstav/cava.git . && \
    git checkout 4915465a38278f452449956d969913f809d51473

RUN ./autogen.sh
RUN ./configure --prefix=/usr
RUN mkdir -p input/.deps output/.deps
RUN make
RUN make install DESTDIR=/install

FROM scratch
COPY --from=builder /install /
