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
# renovate: datasource=git-refs depName=greetd packageName=https://git.sr.ht/~kennylevinsen/greetd versioning=loose
RUN git clone https://git.sr.ht/~kennylevinsen/greetd . && \
    git checkout 51c1f332a09eb4acc8e66655df558f25a8dc62d3
RUN cargo build --release

# Create PAM file (Fedora Standard)
RUN echo "#%PAM-1.0" > greetd.pam && \
    echo "auth       substack    system-auth" >> greetd.pam && \
    echo "-auth      optional    pam_gnome_keyring.so" >> greetd.pam && \
    echo "-auth      optional    pam_kwallet5.so" >> greetd.pam && \
    echo "-auth      optional    pam_kwallet.so" >> greetd.pam && \
    echo "auth       include     postlogin" >> greetd.pam && \
    echo "" >> greetd.pam && \
    echo "account    required    pam_sepermit.so" >> greetd.pam && \
    echo "account    required    pam_nologin.so" >> greetd.pam && \
    echo "account    include     system-auth" >> greetd.pam && \
    echo "" >> greetd.pam && \
    echo "password   include     system-auth" >> greetd.pam && \
    echo "" >> greetd.pam && \
    echo "session    required    pam_selinux.so close" >> greetd.pam && \
    echo "session    required    pam_loginuid.so" >> greetd.pam && \
    echo "session    required    pam_selinux.so open" >> greetd.pam && \
    echo "session    optional    pam_keyinit.so force revoke" >> greetd.pam && \
    echo "session    required    pam_namespace.so" >> greetd.pam && \
    echo "session    include     system-auth" >> greetd.pam && \
    echo "-session   optional    pam_gnome_keyring.so auto_start" >> greetd.pam && \
    echo "-session   optional    pam_kwallet5.so auto_start" >> greetd.pam && \
    echo "-session   optional    pam_kwallet.so auto_start" >> greetd.pam && \
    echo "session    include     postlogin" >> greetd.pam

# Create greetd-greeter PAM file (Copy of greetd for now)
RUN cp greetd.pam greetd-greeter.pam

# Create niri session file
RUN mkdir -p /usr/share/wayland-sessions && \
    echo "[Desktop Entry]" > niri.desktop && \
    echo "Name=Niri" >> niri.desktop && \
    echo "Comment=A scrollable-tiling Wayland compositor" >> niri.desktop && \
    echo "Exec=/usr/bin/niri-session" >> niri.desktop && \
    echo "Type=Application" >> niri.desktop && \
    echo "DesktopNames=niri" >> niri.desktop

# Create sysusers file
RUN echo 'u greetd - "greetd daemon" /var/lib/greetd' > greetd.conf

# Build SELinux policies from source
RUN dnf -y install \
    make \
    bzip2 \
    selinux-policy-devel \
    /usr/share/selinux/devel/Makefile && \
    mkdir /selinux && \
    cd /selinux && \
    echo "policy_module(greetd, 1.0)" > greetd.te && \
    echo "/etc/greetd(/.*)?			gen_context(system_u:object_r:xdm_etc_t,s0)" > greetd.fc && \
    echo "/usr/bin/greetd			--	gen_context(system_u:object_r:xdm_exec_t,s0)" >> greetd.fc && \
    echo "/var/lib/greetd(/.*)?			gen_context(system_u:object_r:xdm_var_lib_t,s0)" >> greetd.fc && \
    echo "/var/run/greetd[^/]*\.sock	-s	gen_context(system_u:object_r:xdm_var_run_t,s0)" >> greetd.fc && \
    echo "/var/run/greetd\.run		--	gen_context(system_u:object_r:xdm_var_run_t,s0)" >> greetd.fc && \
    make -f /usr/share/selinux/devel/Makefile greetd.pp && \
    bzip2 -9 greetd.pp && \
    install -D -m 644 greetd.pp.bz2 /usr/share/selinux/packages/targeted/greetd.pp.bz2

FROM scratch
COPY --from=builder /build/target/release/greetd /usr/bin/greetd
COPY --from=builder /build/target/release/agreety /usr/bin/agreety
COPY --from=builder /build/greetd.service /usr/lib/systemd/system/greetd.service
COPY --from=builder /build/greetd.pam /etc/pam.d/greetd
COPY --from=builder /build/greetd-greeter.pam /etc/pam.d/greetd-greeter
COPY --from=builder /build/niri.desktop /usr/share/wayland-sessions/niri.desktop
COPY --from=builder /build/greetd.conf /usr/lib/sysusers.d/greetd.conf
COPY --from=builder /usr/share/selinux/packages /usr/share/selinux/packages
