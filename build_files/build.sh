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
# service. That is appropriate on a running host but not while
# composing a bootc image.
#
# Install the RPM payload without package scriptlets.
# Runtime configuration and service activation remain an
# explicit host-side action.

dnf5 --setopt=tsflags=noscripts install -y "${NETBIRD_PACKAGE}"

# The generic Gina image must not connect or auto-enable NetBird.
systemctl disable netbird.service 2>/dev/null || true


# ============================================================
# Verified Home Server Packages RPMs shared by both Gina images
# ============================================================

UPSIDE_RPM="$(find /upside-rpm -maxdepth 1 -type f -name 'cockpit-upside-*.noarch.rpm' -print -quit)"
SUPERFILE_RPM="$(find /superfile-rpm -maxdepth 1 -type f -name 'superfile-*.x86_64.rpm' -print -quit)"

test -n "${UPSIDE_RPM}"
test -n "${SUPERFILE_RPM}"

dnf5 install -y "${UPSIDE_RPM}" "${SUPERFILE_RPM}"


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
command -v btop
command -v fastfetch
command -v micro
command -v netbird
command -v spf

rpm -q cockpit-upside
rpm -q superfile

test -f /usr/share/cockpit/upside/manifest.json
test -f /usr/share/licenses/cockpit-upside/LICENSE
test -f /usr/share/licenses/superfile/LICENSE

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
# - install/start the NetBird service
# - run powertop --auto-tune


dnf5 clean all
