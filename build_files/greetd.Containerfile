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

# Create PAM file
RUN echo "#%PAM-1.0" > greetd.pam && \
    echo "auth       include      system-auth" >> greetd.pam && \
    echo "account    include      system-auth" >> greetd.pam && \
    echo "password   include      system-auth" >> greetd.pam && \
    echo "session    include      system-auth" >> greetd.pam

FROM scratch
COPY --from=builder /build/target/release/greetd /usr/bin/greetd
COPY --from=builder /build/target/release/agreety /usr/bin/agreety
COPY --from=builder /build/greetd.service /usr/lib/systemd/system/greetd.service
COPY --from=builder /build/greetd.pam /etc/pam.d/greetd
