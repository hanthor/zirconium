#!/bin/bash

set -xeuo pipefail

install -d /usr/share/zirconium/






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
 
systemctl enable firewalld

# Copy Files
cp -avf "/ctx/files"/. /

# Global Systemd Enables/Presets
GLOBAL_ENABLES=(
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
systemctl enable flatpak-preinstall.service
