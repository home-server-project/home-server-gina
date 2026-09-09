#!/usr/bin/bash

set -ouex pipefail

: "${UCORE_IMAGE:?UCORE_IMAGE must be set by the image build}"

case "${UCORE_IMAGE}" in
    */ucore-hci:*) ;;
    *)
        echo "ERROR: Gina HCI layer requires the uCore HCI base." >&2
        exit 1
        ;;
esac

VIRTUI_RPM="$(find /virtui-manager-rpm -maxdepth 1 -type f -name 'virtui-manager-*.noarch.rpm' -print -quit)"
test -n "${VIRTUI_RPM}"

dnf5 install -y "${VIRTUI_RPM}"

command -v virtui-manager
command -v vmc
command -v websockify

rpm -q virtui-manager
rpm -q novnc
rpm -q python3-websockify

test -d /usr/share/novnc

# The common stage already applied the HCI identity because UCORE_IMAGE points
# at uCore HCI. Confirm it remains intact after adding the HCI-only utility.
# shellcheck disable=SC1091
source /usr/lib/os-release
[[ "${HOME_SERVER_GINA_VARIANT:-}" == "hci" ]]
[[ "${PRETTY_NAME:-}" == Home\ Server\ Gina\ HCI* ]]

dnf5 clean all
