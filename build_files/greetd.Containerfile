FROM quay.io/centos/centos:stream10 AS builder

RUN dnf -y install epel-release && \
    dnf -y --enablerepo=crb install \
    cargo \
    rust \
    git \
    pam-devel \
    gcc \
    pkgconf

WORKDIR /build
RUN git clone https://git.sr.ht/~kennylevinsen/greetd .
RUN cargo build --release

FROM scratch
COPY --from=builder /build/target/release/greetd /usr/bin/greetd
COPY --from=builder /build/target/release/agreety /usr/bin/agreety
COPY --from=builder /build/greetd.service /usr/lib/systemd/system/greetd.service
# Assuming pam file is named 'greetd.pam' in source, renaming to 'greetd'
COPY --from=builder /build/greetd.pam /etc/pam.d/greetd
