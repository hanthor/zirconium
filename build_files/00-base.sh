#!/bin/bash

set -xeuo pipefail

dnf -y remove \
  subscription-manager \
  console-login-helper-messages \
  chrony \
  sssd* \
  qemu-user-static* \
  toolbox

# EPEL
dnf -y install "https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm"
dnf config-manager --set-enabled crb

# Multimidia codecs
dnf config-manager --add-repo=https://negativo17.org/repos/epel-multimedia.repo
dnf config-manager --set-disabled epel-multimedia
dnf -y install --enablerepo=epel-multimedia \
    ffmpeg libavcodec @multimedia gstreamer1-plugins-{bad-free,bad-free-libs,good,base} lame{,-libs} libjxl ffmpegthumbnailer

# Tailscale
dnf config-manager --add-repo "https://pkgs.tailscale.com/stable/centos/10/tailscale.repo"
dnf config-manager --set-disabled "tailscale-stable"
# FIXME: tailscale EPEL10 request: https://bugzilla.redhat.com/show_bug.cgi?id=2349099
dnf -y --enablerepo "tailscale-stable" install \
        tailscale

systemctl enable tailscaled

dnf install -y \
  alsa-firmware \
  alsa-sof-firmware \
  alsa-tools-firmware \
  intel-audio-firmware \
  NetworkManager-wifi \
  atheros-firmware \
  brcmfmac-firmware \
  iwlegacy-firmware \
  iwlwifi-dvm-firmware \
  iwlwifi-mvm-firmware \
  mt7xxx-firmware \
  nxpwireless-firmware \
  realtek-firmware \
  tiwilink-firmware

dnf -y install \
  audit \
  audispd-plugins \
  cifs-utils \
  firewalld \
  fuse \
  fuse-common \
  fwupd \
	gvfs-mtp \
  gvfs-smb \
  libcamera{,-{v4l2,gstreamer,tools}} \
  man-db \
  plymouth \
  plymouth-system-theme \
  steam-devices \
  systemd-container \
  systemd-resolved \
  tuned \
  tuned-ppd \
  unzip \
  whois

systemctl enable auditd
systemctl enable firewalld
systemctl enable systemd-resolved.service

sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/bootc update --quiet|' /usr/lib/systemd/system/bootc-fetch-apply-updates.service
sed -i 's|^OnUnitInactiveSec=.*|OnUnitInactiveSec=7d\nPersistent=true|' /usr/lib/systemd/system/bootc-fetch-apply-updates.timer
sed -i 's|#AutomaticUpdatePolicy.*|AutomaticUpdatePolicy=stage|' /etc/rpm-ostreed.conf
sed -i 's|#LockLayering.*|LockLayering=true|' /etc/rpm-ostreed.conf

systemctl enable bootc-fetch-apply-updates

tee /usr/lib/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = min(ram, 8192)
EOF

tee /usr/lib/systemd/system-preset/91-resolved-default.preset <<'EOF'
enable systemd-resolved.service
EOF
tee /usr/lib/tmpfiles.d/resolved-default.conf <<'EOF'
L /etc/resolv.conf - - - - ../run/systemd/resolve/stub-resolv.conf
EOF

systemctl preset systemd-resolved.service

dnf -y copr enable ublue-os/packages
dnf -y copr disable ublue-os/packages
dnf -y --enablerepo copr:copr.fedorainfracloud.org:ublue-os:packages install \
  ublue-brew \
  uupd \
  ublue-os-udev-rules

# ts so annoying :face_holding_back_tears: :v: 67
sed -i 's|uupd|& --disable-module-distrobox|' /usr/lib/systemd/system/uupd.service

systemctl enable brew-setup.service
systemctl enable uupd.timer

