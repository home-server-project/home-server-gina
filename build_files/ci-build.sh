#!/usr/bin/bash

set -euo pipefail

TARGET_IMAGE="${1:?target image is required}"
TAG="${2:?tag is required}"

# Load repository metadata used by the existing Justfile build recipe.
# Workflow-provided build inputs stay in the environment.
# shellcheck disable=SC1091
source image-template.env

: "${UCORE_IMAGE:?UCORE_IMAGE must be set}"
: "${IMAGE_REPOSITORY:?IMAGE_REPOSITORY must be set}"
: "${UPSIDE_PACKAGE_IMAGE:?UPSIDE_PACKAGE_IMAGE must be set}"
: "${SUPERFILE_PACKAGE_IMAGE:?SUPERFILE_PACKAGE_IMAGE must be set}"
: "${VIRTUI_MANAGER_PACKAGE_IMAGE:?VIRTUI_MANAGER_PACKAGE_IMAGE must be set}"

BUILD_ARGS=(
    --build-arg "UCORE_IMAGE=${UCORE_IMAGE}"
    --build-arg "IMAGE_REPOSITORY=${IMAGE_REPOSITORY}"
    --build-arg "UPSIDE_PACKAGE_IMAGE=${UPSIDE_PACKAGE_IMAGE}"
    --build-arg "SUPERFILE_PACKAGE_IMAGE=${SUPERFILE_PACKAGE_IMAGE}"
    --build-arg "VIRTUI_MANAGER_PACKAGE_IMAGE=${VIRTUI_MANAGER_PACKAGE_IMAGE}"
)

LABELS=()

if [[ -z "$(git status -s)" ]]; then
    GIT_SHA="$(git rev-parse --short HEAD)"

    LABELS+=(
        --label
        "io.artifacthub.package.readme-url=https://raw.githubusercontent.com/${REPO_ORGANIZATION}/${REPOSITORY_NAME}/${GIT_SHA}/README.md"
        --label
        "org.opencontainers.image.documentation=https://raw.githubusercontent.com/${REPO_ORGANIZATION}/${REPOSITORY_NAME}/${GIT_SHA}/README.md"
        --label
        "org.opencontainers.image.source=https://github.com/${REPO_ORGANIZATION}/${REPOSITORY_NAME}/blob/${GIT_SHA}/Containerfile"
        --label
        "org.opencontainers.image.url=https://github.com/${REPO_ORGANIZATION}/${REPOSITORY_NAME}/tree/${GIT_SHA}"
    )
fi

LABELS+=(
    --label "io.artifacthub.package.deprecated=false"
    --label "io.artifacthub.package.keywords=${IMAGE_KEYWORDS}"
    --label "io.artifacthub.package.license=Apache-2.0"
    --label "io.artifacthub.package.logo-url=${IMAGE_LOGO_URL}"
    --label "io.artifacthub.package.prerelease=false"
    --label "org.opencontainers.image.created=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    --label "org.opencontainers.image.description=${IMAGE_DESC}"
    --label "org.opencontainers.image.title=${TARGET_IMAGE}"
    --label "org.opencontainers.image.vendor=${REPO_ORGANIZATION}"
)

podman build \
    "${BUILD_ARGS[@]}" \
    "${LABELS[@]}" \
    --pull=newer \
    --tag "${TARGET_IMAGE}:${TAG}" \
    --file Containerfile \
    .
