#!/usr/bin/bash

set -euo pipefail

: "${UCORE_IMAGE:?UCORE_IMAGE must be set by the image build}"

OS_RELEASE="/usr/lib/os-release"

if [[ ! -f "${OS_RELEASE}" ]]; then
    echo "ERROR: ${OS_RELEASE} is missing." >&2
    exit 1
fi

# Preserve the upstream Fedora/uCore compatibility fields that tooling expects.
# Gina changes the human-facing product identity and adds namespaced provenance.
# shellcheck disable=SC1090
source "${OS_RELEASE}"

BASE_ID="${ID:-}"
BASE_VARIANT_ID="${VARIANT_ID:-}"
BASE_VARIANT="${VARIANT:-}"
BASE_PRETTY_NAME="${PRETTY_NAME:-}"
BASE_VERSION_ID="${VERSION_ID:-}"

if [[ "${BASE_ID}" != "fedora" ]]; then
    echo "ERROR: expected Fedora/uCore base ID=fedora, got '${BASE_ID}'." >&2
    exit 1
fi

if [[ "${BASE_VARIANT_ID}" != "ucore" ]]; then
    echo "ERROR: expected upstream uCore VARIANT_ID=ucore, got '${BASE_VARIANT_ID}'." >&2
    exit 1
fi

case "${UCORE_IMAGE}" in
    */ucore-hci:*)
        GINA_NAME="Home Server Gina HCI"
        GINA_VARIANT="hci"
        GINA_UPSTREAM="Universal Blue uCore HCI LTS"
        ;;
    */ucore:*)
        GINA_NAME="Home Server Gina"
        GINA_VARIANT="standard"
        GINA_UPSTREAM="Universal Blue uCore LTS"
        ;;
    *)
        echo "ERROR: unsupported upstream image '${UCORE_IMAGE}'." >&2
        exit 1
        ;;
esac

GINA_PRETTY_NAME="${GINA_NAME} (${GINA_UPSTREAM})"

TMP="$(mktemp)"
trap 'rm -f "${TMP}"' EXIT

awk -v name="${GINA_NAME}" -v pretty="${GINA_PRETTY_NAME}" '
    BEGIN {
        name_written = 0
        pretty_written = 0
    }
    /^NAME=/ {
        print "NAME=\"" name "\""
        name_written = 1
        next
    }
    /^PRETTY_NAME=/ {
        print "PRETTY_NAME=\"" pretty "\""
        pretty_written = 1
        next
    }
    /^HOME_SERVER_GINA_/ { next }
    { print }
    END {
        if (!name_written) {
            print "NAME=\"" name "\""
        }
        if (!pretty_written) {
            print "PRETTY_NAME=\"" pretty "\""
        }
    }
' "${OS_RELEASE}" > "${TMP}"

cat >> "${TMP}" <<EOF
HOME_SERVER_GINA_NAME="${GINA_NAME}"
HOME_SERVER_GINA_VARIANT="${GINA_VARIANT}"
HOME_SERVER_GINA_CHANNEL="lts"
HOME_SERVER_GINA_UPSTREAM="${GINA_UPSTREAM}"
HOME_SERVER_GINA_UPSTREAM_IMAGE="${UCORE_IMAGE}"
HOME_SERVER_GINA_BASE_ID="${BASE_ID}"
HOME_SERVER_GINA_BASE_VARIANT_ID="${BASE_VARIANT_ID}"
HOME_SERVER_GINA_BASE_VARIANT="${BASE_VARIANT}"
HOME_SERVER_GINA_BASE_VERSION_ID="${BASE_VERSION_ID}"
HOME_SERVER_GINA_BASE_PRETTY_NAME="${BASE_PRETTY_NAME}"
HOME_SERVER_GINA_REPOSITORY="https://github.com/home-server-project/home-server-gina"
EOF

install -m0644 "${TMP}" "${OS_RELEASE}"

# Validate the final identity without changing the upstream compatibility fields.
unset NAME ID VARIANT_ID PRETTY_NAME HOME_SERVER_GINA_NAME HOME_SERVER_GINA_VARIANT HOME_SERVER_GINA_CHANNEL HOME_SERVER_GINA_UPSTREAM HOME_SERVER_GINA_UPSTREAM_IMAGE HOME_SERVER_GINA_BASE_ID HOME_SERVER_GINA_BASE_VARIANT_ID HOME_SERVER_GINA_BASE_VARIANT HOME_SERVER_GINA_BASE_VERSION_ID HOME_SERVER_GINA_BASE_PRETTY_NAME HOME_SERVER_GINA_REPOSITORY
# shellcheck disable=SC1090
source "${OS_RELEASE}"

[[ "${NAME:-}" == "${GINA_NAME}" ]]
[[ "${ID:-}" == "${BASE_ID}" ]]
[[ "${VARIANT_ID:-}" == "${BASE_VARIANT_ID}" ]]
[[ "${PRETTY_NAME:-}" == "${GINA_PRETTY_NAME}" ]]
[[ "${HOME_SERVER_GINA_NAME:-}" == "${GINA_NAME}" ]]
[[ "${HOME_SERVER_GINA_VARIANT:-}" == "${GINA_VARIANT}" ]]
[[ "${HOME_SERVER_GINA_CHANNEL:-}" == "lts" ]]
[[ "${HOME_SERVER_GINA_UPSTREAM_IMAGE:-}" == "${UCORE_IMAGE}" ]]
[[ "${HOME_SERVER_GINA_BASE_ID:-}" == "${BASE_ID}" ]]
[[ "${HOME_SERVER_GINA_BASE_VARIANT_ID:-}" == "${BASE_VARIANT_ID}" ]]
[[ "${HOME_SERVER_GINA_REPOSITORY:-}" == "https://github.com/home-server-project/home-server-gina" ]]

if grep -q 'Home Server uCore' "${OS_RELEASE}"; then
    echo "ERROR: legacy Home Server uCore presentation remains in ${OS_RELEASE}." >&2
    exit 1
fi

echo "Applied ${GINA_NAME} identity while preserving upstream ID=${ID} VARIANT_ID=${VARIANT_ID}."
