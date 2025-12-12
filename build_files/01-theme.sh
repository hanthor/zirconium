#!/bin/bash

set -xeuo pipefail

install -d /usr/share/zirconium/

dnf -y copr enable yalter/niri-git
dnf -y copr disable yalter/niri-git
echo "priority=1" | tee -a /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:yalter:niri-git.repo
dnf -y --enablerepo copr:copr.fedorainfracloud.org:yalter:niri-git \
    install --setopt=install_weak_deps=False \
    niri

dnf -y copr enable jreilly1821/danklinux
dnf -y copr disable jreilly1821/danklinux
dnf -y copr enable  yselkowitz/cosmic-epel
dnf -y copr disable yselkowitz/cosmic-epel
dnf -y --enablerepo copr:copr.fedorainfracloud.org:jreilly1821:danklinux install quickshell-git


dnf -y \
    --enablerepo copr:copr.fedorainfracloud.org:jreilly1821:danklinux \
    --enablerepo copr:copr.fedorainfracloud.org:yselkowitz:cosmic-epel \
    install --setopt=install_weak_deps=False \
    dms \
    dms-cli \
    dms-greeter \
    dgop \
    matugen \
    cliphist

# Install packages available in CentOS/EPEL
dnf -y install \
    chezmoi \
    ddcutil \
    fastfetch \
    flatpak \
    fpaste \
    fzf \
    git-core \
    gnome-keyring \
    gnome-keyring-pam \
    greetd \
    greetd-selinux \
    just \
    libwayland-server \
    nautilus \
    orca \
    pipewire \
    steam-devices \
    webp-pixbuf-loader \
    wireplumber \
    wl-clipboard \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    xdg-user-dirs

# Install packages from Fedora 43 that are not available in EPEL or CentOS
# These are installed directly from kojipkgs URLs
# Detect architecture
ARCH=$(uname -m)
case "${ARCH}" in
  x86_64|amd64)
    FEDORA_ARCH="x86_64"
    ;;
  aarch64|arm64)
    FEDORA_ARCH="aarch64"
    ;;
  *)
    echo "Unsupported architecture: ${ARCH}"
    exit 1
    ;;
esac

# Base URL for Fedora 43 packages on koji
KOJI_BASE="https://kojipkgs.fedoraproject.org//packages"

# Install dependencies from Fedora 43 first
dnf -y install \
    "${KOJI_BASE}/highway/1.3.0/1.fc43/${FEDORA_ARCH}/highway-1.3.0-1.fc43.${FEDORA_ARCH}.rpm" \
    "${KOJI_BASE}/libjxl/0.11.1/7.fc43/${FEDORA_ARCH}/libjxl-0.11.1-7.fc43.${FEDORA_ARCH}.rpm" \
    "${KOJI_BASE}/iniparser/4.2.6/3.fc43/${FEDORA_ARCH}/iniparser-4.2.6-3.fc43.${FEDORA_ARCH}.rpm" \
    "${KOJI_BASE}/fcft/3.3.2/2.fc43/${FEDORA_ARCH}/fcft-3.3.2-2.fc43.${FEDORA_ARCH}.rpm" \
    "${KOJI_BASE}/utf8proc/2.10.0/2.fc43/${FEDORA_ARCH}/utf8proc-2.10.0-2.fc43.${FEDORA_ARCH}.rpm" \
    "${KOJI_BASE}/glycin/2.0.4/1.fc43/${FEDORA_ARCH}/glycin-loaders-2.0.4-1.fc43.${FEDORA_ARCH}.rpm"

# Install arch-specific packages from Fedora 43
dnf -y install \
    "${KOJI_BASE}/brightnessctl/0.5.1/14.fc43/${FEDORA_ARCH}/brightnessctl-0.5.1-14.fc43.${FEDORA_ARCH}.rpm" \
    "${KOJI_BASE}/cava/0.10.2/5.fc43/${FEDORA_ARCH}/cava-0.10.2-5.fc43.${FEDORA_ARCH}.rpm" \
    "${KOJI_BASE}/foot/1.25.0/1.fc43/${FEDORA_ARCH}/foot-1.25.0-1.fc43.${FEDORA_ARCH}.rpm" \
    "${KOJI_BASE}/glycin/2.0.4/1.fc43/${FEDORA_ARCH}/glycin-thumbnailer-2.0.4-1.fc43.${FEDORA_ARCH}.rpm" \
    "${KOJI_BASE}/tuigreet/0.9.1/4.fc43/${FEDORA_ARCH}/tuigreet-0.9.1-4.fc43.${FEDORA_ARCH}.rpm" \
    "${KOJI_BASE}/wlsunset/0.4.0/4.fc43/${FEDORA_ARCH}/wlsunset-0.4.0-4.fc43.${FEDORA_ARCH}.rpm" \
    "${KOJI_BASE}/xwayland-satellite/0.7/1.fc43/${FEDORA_ARCH}/xwayland-satellite-0.7-1.fc43.${FEDORA_ARCH}.rpm"

# Install noarch packages from Fedora 43
dnf -y install \
    "${KOJI_BASE}/input-remapper/2.2.0/1.fc43/noarch/input-remapper-2.2.0-1.fc43.noarch.rpm" \
    "${KOJI_BASE}/udiskie/2.5.8/2.fc43/noarch/python3-udiskie-2.5.8-2.fc43.noarch.rpm" \
    "${KOJI_BASE}/udiskie/2.5.8/2.fc43/noarch/udiskie-2.5.8-2.fc43.noarch.rpm"

dnf install -y --setopt=install_weak_deps=False \
    kf6-kirigami \
    qt6ct \
    polkit-kde \
    plasma-breeze \
    kf6-qqc2-desktop-style

sed --sandbox -i -e '/gnome_keyring.so/ s/-auth/auth/ ; /gnome_keyring.so/ s/-session/session/' /etc/pam.d/greetd

# Codecs for video thumbnails on nautilus
dnf config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-multimedia.repo
dnf config-manager setopt fedora-multimedia.enabled=0
dnf -y install --enablerepo=fedora-multimedia \
    ffmpeg libavcodec @multimedia gstreamer1-plugins-{bad-free,bad-free-libs,good,base} lame{,-libs} libjxl ffmpegthumbnailer

add_wants_niri() {
    sed -i "s/\[Unit\]/\[Unit\]\nWants=$1/" "/usr/lib/systemd/user/niri.service"
}
add_wants_niri cliphist.service
add_wants_niri swayidle.service
add_wants_niri udiskie.service
add_wants_niri foot.service
add_wants_niri xwayland-satellite.service
cat /usr/lib/systemd/user/niri.service

systemctl enable greetd
systemctl enable firewalld

# Sacrificed to the :steamhappy: emoji old god
dnf install -y \
    default-fonts-core-emoji \
    google-noto-color-emoji-fonts \
    google-noto-emoji-fonts \
    glibc-all-langpacks \
    default-fonts

cp -avf "/ctx/files"/. /

systemctl enable flatpak-preinstall.service
systemctl enable --global chezmoi-init.service
systemctl enable --global foot.service
systemctl enable --global chezmoi-update.timer
systemctl enable --global dms.service
systemctl enable --global cliphist.service
systemctl enable --global gnome-keyring-daemon.socket
systemctl enable --global gnome-keyring-daemon.service
systemctl enable --global swayidle.service
systemctl enable --global udiskie.service
systemctl enable --global xwayland-satellite.service
systemctl preset --global chezmoi-init
systemctl preset --global chezmoi-update
systemctl preset --global cliphist
systemctl preset --global swayidle
systemctl preset --global udiskie
systemctl preset --global foot
systemctl preset --global xwayland-satellite

git clone "https://github.com/noctalia-dev/noctalia-shell.git" /usr/share/zirconium/noctalia-shell
cp /usr/share/zirconium/skel/Pictures/Wallpapers/mountains.png /usr/share/zirconium/noctalia-shell/Assets/Wallpaper/noctalia.png
cp -rf /usr/share/zirconium/skel/* /etc/skel
git clone "https://github.com/zirconium-dev/zdots.git" /usr/share/zirconium/zdots
install -d /etc/niri/
cp -f /usr/share/zirconium/zdots/dot_config/niri/config.kdl /etc/niri/config.kdl
file /etc/niri/config.kdl | grep -F -e "empty" -v
stat /etc/niri/config.kdl
cp -f /usr/share/zirconium/pixmaps/watermark.png /usr/share/plymouth/themes/spinner/watermark.png

mkdir -p "/usr/share/fonts/Maple Mono"

MAPLE_TMPDIR="$(mktemp -d)"
trap 'rm -rf "${MAPLE_TMPDIR}"' EXIT

LATEST_RELEASE_FONT="$(curl "https://api.github.com/repos/subframe7536/maple-font/releases/latest" | jq '.assets[] | select(.name == "MapleMono-Variable.zip") | .browser_download_url' -rc)"
curl -fSsLo "${MAPLE_TMPDIR}/maple.zip" "${LATEST_RELEASE_FONT}"
unzip "${MAPLE_TMPDIR}/maple.zip" -d "/usr/share/fonts/Maple Mono"

fc-cache --force --really-force --system-only --verbose # recreate font-cache to pick up the added fonts

echo 'source /usr/share/zirconium/shell/pure.bash' | tee -a "/etc/bashrc"
