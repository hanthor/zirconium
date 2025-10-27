#!/bin/bash

set -xeuo pipefail

install -d /usr/share/zirconium/

# ============================================================================
# Arrays for package management
# ============================================================================

# Base packages (non-COPR)
declare -a BASE_PACKAGES=(
    accountsservice
    brightnessctl
    cava
    chezmoi
    ddcutil
    fastfetch
    flatpak
    fpaste
    fzf
    git-core
    gnome-keyring
    greetd
    greetd-selinux
    input-remapper
    just
    kf6-kirigami
    kf6-qqc2-desktop-style
    nautilus
    orca
    pipewire
    plasma-breeze
    polkit-kde
    qt6ct
    qt6-qtmultimedia
    steam-devices
    tuigreet
    udiskie
    wireplumber
    wl-clipboard
    wlsunset
    xdg-desktop-portal-gnome
    xdg-user-dirs
    xwayland-satellite
    default-fonts-core-emoji
    google-noto-color-emoji-fonts
    google-noto-emoji-fonts
    glibc-all-langpacks
    default-fonts
)

# COPR packages (will be populated by manage_copr_packages function)
declare -a COPR_PACKAGES=()

# COPR repos for building enablerepo flags (populated by manage_copr_packages function)
declare -a COPR_REPOS_USED=()

# ============================================================================
# Functions
# ============================================================================

# Function to manage COPR repo and add packages to COPR_PACKAGES array
manage_copr_packages() {
    local copr_repo="$1"
    shift  # remaining args are package names
    local packages=("$@")
    
    # Enable COPR repo
    dnf -y copr enable "${copr_repo}"
    
    # Track this repo for later enablerepo flags
    COPR_REPOS_USED+=("${copr_repo}")
    
    # Add packages to COPR_PACKAGES array
    for pkg in "${packages[@]}"; do
        COPR_PACKAGES+=("${pkg}")
    done
}

# ============================================================================
# Enable COPR repos and collect packages
# ============================================================================

manage_copr_packages "yalter/niri-git" niri
manage_copr_packages "errornointernet/quickshell" quickshell-git
manage_copr_packages "scottames/ghostty" ghostty
manage_copr_packages "zirconium/packages" matugen cliphist
manage_copr_packages "avengemedia/dms" dms
manage_copr_packages "avengemedia/danklinux" dgop ghostty hyprpicker matugen

# Set priority for niri-git repo
echo "priority=1" | tee -a /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:yalter:niri-git.repo

# ============================================================================
# Disable all COPR repos (will selectively enable in final install)
# ============================================================================

for copr_repo in "${COPR_REPOS_USED[@]}"; do
    dnf -y copr disable "${copr_repo}"
done

# ============================================================================
# Remove packages
# ============================================================================

dnf -y remove alacritty

# ============================================================================
# Final installation with all repos enabled
# ============================================================================

# Build enablerepo flags for all COPR repos used
declare -a ENABLEREPO_FLAGS=()
for copr_repo in "${COPR_REPOS_USED[@]}"; do
    # Convert owner/repo to copr namespace format
    repo_namespace="copr:copr.fedorainfracloud.org:${copr_repo//\//:}"
    ENABLEREPO_FLAGS+=("--enablerepo=${repo_namespace}")
done

# Install all packages in one transaction
dnf -y install --setopt=install_weak_deps=False \
    "${ENABLEREPO_FLAGS[@]}" \
    "${BASE_PACKAGES[@]}" \
    "${COPR_PACKAGES[@]}"

rm -rf /usr/share/doc/niri
rm -rf /usr/share/doc/just

sed -i '/gnome_keyring.so/ s/-auth/auth/ ; /gnome_keyring.so/ s/-session/session/' /etc/pam.d/greetd
cat /etc/pam.d/greetd


sed -i "s/After=.*/After=graphical-session.target/" /usr/lib/systemd/user/plasma-polkit-agent.service

# Codecs for video thumbnails on nautilus
dnf config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-multimedia.repo
dnf config-manager setopt fedora-multimedia.enabled=0
dnf -y install --enablerepo=fedora-multimedia \
    ffmpeg libavcodec @multimedia gstreamer1-plugins-{bad-free,bad-free-libs,good,base} lame{,-libs} libjxl ffmpegthumbnailer

add_wants_niri() {
    sed -i "s/\[Unit\]/\[Unit\]\nWants=$1/" "/usr/lib/systemd/user/niri.service"
}
add_wants_niri plasma-polkit-agent.service
add_wants_niri swayidle.service
add_wants_niri udiskie.service
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
systemctl enable --global app-com.mitchellh.ghostty.service
systemctl enable --global chezmoi-update.timer
systemctl enable --global plasma-polkit-agent.service
systemctl enable --global swayidle.service
systemctl enable --global udiskie.service
systemctl enable --global xwayland-satellite.service
systemctl preset --global app-com.mitchellh.ghostty.service
systemctl preset --global chezmoi-init
systemctl preset --global chezmoi-update
systemctl preset --global plasma-polkit-agent
systemctl preset --global swayidle
systemctl preset --global udiskie
systemctl preset --global xwayland-satellite

git clone "https://github.com/hanthor/zdots.git" /usr/share/zirconium/zdots
install -d /etc/niri/
cp -f /usr/share/zirconium/zdots/dot_config/niri/config.kdl /etc/niri/config.kdl
file /etc/niri/config.kdl | grep -F -e "empty" -v
stat /etc/niri/config.kdl

mkdir -p "/usr/share/fonts/Maple Mono"

MAPLE_TMPDIR="$(mktemp -d)"
trap 'rm -rf "${MAPLE_TMPDIR}"' EXIT

LATEST_RELEASE_FONT="$(curl "https://api.github.com/repos/subframe7536/maple-font/releases/latest" | jq '.assets[] | select(.name == "MapleMono-Variable.zip") | .browser_download_url' -rc)"
curl -fSsLo "${MAPLE_TMPDIR}/maple.zip" "${LATEST_RELEASE_FONT}"
unzip "${MAPLE_TMPDIR}/maple.zip" -d "/usr/share/fonts/Maple Mono"

echo 'source /usr/share/zirconium/shell/pure.bash' | tee -a "/etc/bashrc"
