#!/bin/bash

set -xeuo pipefail

install -d /usr/share/zirconium/

# --- COPR Helper ---
enable_copr() {
    dnf -y copr enable "$1"
    dnf -y copr disable "$1"
}

# --- Setup Repositories ---
# enable_copr "yalter/niri-git"
echo "priority=1" | tee -a /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:yalter:niri-git.repo

# enable_copr "jreilly1821/danklinux"
# enable_copr "yselkowitz/cosmic-epel"

# --- Define Package Groups ---

# COPR Packages
COPR_PACKAGES=(
    # niri - OCI
    # quickshell-git - OCI
    # dms - OCI
    # dms-cli - OCI
    # dms-greeter - OCI
    # dgop - OCI
    # matugen - OCI
    # cliphist - OCI
)

# Standard Packages (CentOS/EPEL/Fedora)
STANDARD_PACKAGES=(
    chezmoi
    ddcutil
    fastfetch
    flatpak
    fpaste
    fzf
    git-core
    gnome-keyring
    gnome-keyring-pam
    # greetd
    # greetd-selinux
    just
    iniparser
    libwayland-server
    nautilus
    orca
    pipewire
    steam-devices
    webp-pixbuf-loader
    wireplumber
    wl-clipboard
    xdg-desktop-portal-gnome
    xdg-desktop-portal-gtk
    xdg-user-dirs
    # KDE/Qt components - Commented out due to conflict with quickshell-git (Qt 6.10) vs EPEL (Qt 6.9)
    # kf6-kirigami
    # qt6ct
    # polkit-kde
    # plasma-breeze
    # kf6-qqc2-desktop-style
    # Fonts & Emoji
    default-fonts-core-emoji
    google-noto-color-emoji-fonts
    google-noto-emoji-fonts
    glibc-all-langpacks
    default-fonts
)

# Koji / Fedora 43 Packages
ARCH=$(uname -m)
case "${ARCH}" in
  x86_64|amd64) FEDORA_ARCH="x86_64" ;;
  aarch64|arm64) FEDORA_ARCH="aarch64" ;;
  *) echo "Unsupported architecture: ${ARCH}"; exit 1 ;;
esac

KOJI_BASE="https://kojipkgs.fedoraproject.org//packages"
KOJI_PACKAGES=(
    "${KOJI_BASE}/highway/1.3.0/1.fc43/${FEDORA_ARCH}/highway-1.3.0-1.fc43.${FEDORA_ARCH}.rpm"
    # "${KOJI_BASE}/libjxl/0.11.1/7.fc43/${FEDORA_ARCH}/libjxl-0.11.1-7.fc43.${FEDORA_ARCH}.rpm"
    "${KOJI_BASE}/iniparser/4.2.6/3.fc43/${FEDORA_ARCH}/iniparser-4.2.6-3.fc43.${FEDORA_ARCH}.rpm"
    "${KOJI_BASE}/fcft/3.3.2/2.fc43/${FEDORA_ARCH}/fcft-3.3.2-2.fc43.${FEDORA_ARCH}.rpm"
    "${KOJI_BASE}/utf8proc/2.10.0/2.fc43/${FEDORA_ARCH}/utf8proc-2.10.0-2.fc43.${FEDORA_ARCH}.rpm"
    # "${KOJI_BASE}/glycin/2.0.4/1.fc43/${FEDORA_ARCH}/glycin-loaders-2.0.4-1.fc43.${FEDORA_ARCH}.rpm"
    "${KOJI_BASE}/brightnessctl/0.5.1/14.fc43/${FEDORA_ARCH}/brightnessctl-0.5.1-14.fc43.${FEDORA_ARCH}.rpm"
    "${KOJI_BASE}/cava/0.10.2/5.fc43/${FEDORA_ARCH}/cava-0.10.2-5.fc43.${FEDORA_ARCH}.rpm"
    "${KOJI_BASE}/foot/1.25.0/1.fc43/${FEDORA_ARCH}/foot-1.25.0-1.fc43.${FEDORA_ARCH}.rpm"
    # "${KOJI_BASE}/glycin/2.0.4/1.fc43/${FEDORA_ARCH}/glycin-thumbnailer-2.0.4-1.fc43.${FEDORA_ARCH}.rpm"
    # "${KOJI_BASE}/tuigreet/0.9.1/4.fc43/${FEDORA_ARCH}/tuigreet-0.9.1-4.fc43.${FEDORA_ARCH}.rpm"
    # "${KOJI_BASE}/wlsunset/0.4.0/4.fc43/${FEDORA_ARCH}/wlsunset-0.4.0-4.fc43.${FEDORA_ARCH}.rpm"
    # "${KOJI_BASE}/xwayland-satellite/0.7/1.fc43/${FEDORA_ARCH}/xwayland-satellite-0.7-1.fc43.${FEDORA_ARCH}.rpm"
    # "${KOJI_BASE}/input-remapper/2.2.0/1.fc43/noarch/input-remapper-2.2.0-1.fc43.noarch.rpm"
    # "${KOJI_BASE}/udiskie/2.5.8/2.fc43/noarch/python3-udiskie-2.5.8-2.fc43.noarch.rpm"
    # "${KOJI_BASE}/udiskie/2.5.8/2.fc43/noarch/udiskie-2.5.8-2.fc43.noarch.rpm"
)

# --- Install Packages ---

# Install Groups
# Install Groups
# dnf -y install \
#     --setopt=install_weak_deps=False \
#     --enablerepo copr:copr.fedorainfracloud.org:yalter:niri-git \
#     --enablerepo copr:copr.fedorainfracloud.org:jreilly1821:danklinux \
#     --enablerepo copr:copr.fedorainfracloud.org:yselkowitz:cosmic-epel \
#     "${COPR_PACKAGES[@]}"

dnf -y install \
    "${STANDARD_PACKAGES[@]}"

# dnf -y install "${KOJI_PACKAGES[@]}"

# --- Configurations ---

# Greetd User
groupadd -r -f video
useradd -r -M -G video -s /sbin/nologin greetd

# Greetd PAM fix
# sed --sandbox -i -e '/gnome_keyring.so/ s/-auth/auth/ ; /gnome_keyring.so/ s/-session/session/' /etc/pam.d/greetd
cat > /etc/pam.d/greetd <<EOF
#%PAM-1.0
auth       include      system-auth
auth       optional     pam_gnome_keyring.so
account    include      system-auth
password   include      system-auth
session    include      system-auth
session    optional     pam_gnome_keyring.so auto_start
EOF

# Multimedia
dnf config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-multimedia.repo
dnf config-manager setopt fedora-multimedia.enabled=0
dnf -y install --enablerepo=fedora-multimedia \
    ffmpeg libavcodec @multimedia gstreamer1-plugins-{bad-free,bad-free-libs,good,base} lame{,-libs} ffmpegthumbnailer

# Systemd Niri Wants
NIRI_SERVICES=(
    cliphist.service
    swayidle.service
    udiskie.service
    foot.service
    xwayland-satellite.service
)
for service in "${NIRI_SERVICES[@]}"; do
    sed -i "s/\[Unit\]/\[Unit\]\nWants=${service}/" "/usr/lib/systemd/user/niri.service"
done
cat /usr/lib/systemd/user/niri.service

# Services
systemctl enable greetd firewalld

# Copy Files
cp -avf "/ctx/files"/. /

# Global Systemd Enables/Presets
GLOBAL_ENABLES=(
    flatpak-preinstall.service
    chezmoi-init.service
    foot.service
    chezmoi-update.timer
    dms.service
    cliphist.service
    gnome-keyring-daemon.socket
    gnome-keyring-daemon.service
    swayidle.service
    udiskie.service
    xwayland-satellite.service
)
GLOBAL_PRESETS=(
    chezmoi-init
    chezmoi-update
    cliphist
    swayidle
    udiskie
    foot
    xwayland-satellite
)

for unit in "${GLOBAL_ENABLES[@]}"; do systemctl enable --global "$unit"; done
for unit in "${GLOBAL_PRESETS[@]}"; do systemctl preset --global "$unit"; done

# Theme & Dotfiles
git clone "https://github.com/noctalia-dev/noctalia-shell.git" /usr/share/zirconium/noctalia-shell
cp /usr/share/zirconium/skel/Pictures/Wallpapers/mountains.png /usr/share/zirconium/noctalia-shell/Assets/Wallpaper/noctalia.png
cp -rf /usr/share/zirconium/skel/* /etc/skel

git clone "https://github.com/zirconium-dev/zdots.git" /usr/share/zirconium/zdots
install -d /etc/niri/
cp -f /usr/share/zirconium/zdots/dot_config/niri/config.kdl /etc/niri/config.kdl

# Verification
file /etc/niri/config.kdl | grep -F -e "empty" -v
stat /etc/niri/config.kdl
cp -f /usr/share/zirconium/pixmaps/watermark.png /usr/share/plymouth/themes/spinner/watermark.png

# Fonts
mkdir -p "/usr/share/fonts/Maple Mono"
MAPLE_TMPDIR="$(mktemp -d)"
trap 'rm -rf "${MAPLE_TMPDIR}"' EXIT

LATEST_RELEASE_FONT="$(curl "https://api.github.com/repos/subframe7536/maple-font/releases/latest" | jq '.assets[] | select(.name == "MapleMono-Variable.zip") | .browser_download_url' -rc)"
curl -fSsLo "${MAPLE_TMPDIR}/maple.zip" "${LATEST_RELEASE_FONT}"
unzip "${MAPLE_TMPDIR}/maple.zip" -d "/usr/share/fonts/Maple Mono"

fc-cache --force --really-force --system-only --verbose

# Bashrc
echo 'source /usr/share/zirconium/shell/pure.bash' | tee -a "/etc/bashrc"
