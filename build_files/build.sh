#!/usr/bin/bash

set -ouex pipefail

# The build must tell this image which GHCR repository it belongs to.
: "${IMAGE_REPOSITORY:?IMAGE_REPOSITORY must be set by the image build}"
: "${UCORE_IMAGE:?UCORE_IMAGE must be set by the image build}"

# Load the human-readable Gina software declaration.
source /ctx/software.env

: "${GINA_EXTRA_PACKAGES:?GINA_EXTRA_PACKAGES must be set in software.env}"
: "${NETBIRD_PACKAGE:?NETBIRD_PACKAGE must be set in software.env}"


# Copy declarative system files into the image.
cp -avf /ctx/system_files/. /


# jq is needed by install-image-trust.sh.
dnf5 install -y jq


# Trust the exact custom-image repository currently being built.
/ctx/install-image-trust.sh "${IMAGE_REPOSITORY}"


# ============================================================
# Native Fedora host tools added by Gina
# ============================================================

read -r -a extra_packages <<< "${GINA_EXTRA_PACKAGES}"

dnf5 install -y "${extra_packages[@]}"


# ============================================================
# NetBird
# ============================================================
#
# NetBird's RPM %post tries to install and start its systemd
# service. Starting a live daemon is not appropriate while composing
# a bootc image, so install the RPM payload without package scriptlets,
# then use NetBird's supported CLI to install the service definition
# explicitly and enable it for normal boot-time availability.

dnf5 --setopt=tsflags=noscripts install -y "${NETBIRD_PACKAGE}"

SYSTEMD_OFFLINE=1 netbird service install


# ============================================================
# Verified Home Server Packages RPM shared by both Gina images
# ============================================================

UPSIDE_RPM="$(find /upside-rpm -maxdepth 1 -type f -name 'cockpit-upside-*.noarch.rpm' -print -quit)"

test -n "${UPSIDE_RPM}"

dnf5 install -y "${UPSIDE_RPM}"


# ============================================================
# Homebrew bootc integration
# ============================================================

systemctl preset brew-setup.service brew-update.timer
systemctl disable brew-upgrade.timer 2>/dev/null || true


# The common Gina layer must stay independent of VirtUI Manager.
! rpm -q virtui-manager >/dev/null 2>&1
! command -v virtui-manager >/dev/null 2>&1


# ============================================================
# Gina identity
# ============================================================
#
# Keep Fedora/uCore compatibility identity fields intact while making
# the downstream presentation explicit as Home Server Gina / Gina HCI.

bash /ctx/apply-gina-identity.sh


# ============================================================
# Build-time validation
# ============================================================

command -v upsc
command -v nut-scanner
command -v powertop
command -v netbird
test -f /etc/systemd/system/netbird.service
test "$(systemctl is-enabled netbird.service)" = "enabled"
command -v file
command -v git
command -v zstd
command -v gcc
command -v g++
command -v make
command -v ps

rpm -q cockpit-upside
rpm -q file git zstd gcc gcc-c++ make procps-ng

test -f /usr/share/cockpit/upside/manifest.json
test -f /usr/share/licenses/cockpit-upside/LICENSE

test -f /usr/share/homebrew.tar.zst
test -f /usr/lib/systemd/system/brew-setup.service
test -f /usr/lib/systemd/system/brew-update.service
test -f /usr/lib/systemd/system/brew-update.timer
test -f /usr/lib/systemd/system/brew-upgrade.service
test -f /usr/lib/systemd/system/brew-upgrade.timer
test -f /etc/profile.d/brew.sh
tar --zstd -tf /usr/share/homebrew.tar.zst | grep -Eq '(^|/)home/linuxbrew/.linuxbrew/bin/brew$'
test "$(systemctl is-enabled brew-setup.service)" = "enabled"
test "$(systemctl is-enabled brew-update.timer)" = "enabled"
test "$(systemctl is-enabled brew-upgrade.timer 2>/dev/null || true)" = "disabled"

# Confirm the final image presents itself as Gina while preserving uCore identity.
# shellcheck disable=SC1091
source /usr/lib/os-release
[[ "${ID:-}" == "fedora" ]]
[[ "${VARIANT_ID:-}" == "ucore" ]]
[[ "${HOME_SERVER_GINA_CHANNEL:-}" == "lts" ]]
[[ "${HOME_SERVER_GINA_REPOSITORY:-}" == "https://github.com/home-server-project/home-server-gina" ]]
[[ "${PRETTY_NAME:-}" == Home\ Server\ Gina* ]]


# Deliberately NOT done here:
#
# - enable/configure NUT
# - add UPS credentials/hardware-specific settings
# - configure/connect NetBird
# - start the NetBird service during image composition
# - run powertop --auto-tune


dnf5 clean all
