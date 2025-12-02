#!/usr/bin/env bash

set -xeuo pipefail

dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
dnf config-manager setopt docker-ce-stable.enabled=0
dnf -y install --enablerepo='docker-ce-stable' docker-ce docker-ce-cli docker-compose-plugin

systemctl enable --global ssh-agent

ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose
mkdir -p /usr/lib/sysctl.d
echo "net.ipv4.ip_forward = 1" >/usr/lib/sysctl.d/docker-ce.conf

sed -i 's/enable docker/disable docker/' /usr/lib/systemd/system-preset/90-default.preset
systemctl preset docker.service docker.socket

cat >/usr/lib/sysusers.d/docker.conf <<'EOF'
g docker -
EOF
