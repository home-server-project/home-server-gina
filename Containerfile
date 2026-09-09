# GitHub Actions supplies the selected upstream image through the build matrix.
# These values are the normal local-build defaults.
ARG UCORE_IMAGE=ghcr.io/ublue-os/ucore:lts
ARG IMAGE_REPOSITORY=ghcr.io/home-server-project/home-server-gina
ARG UPSIDE_PACKAGE_IMAGE=ghcr.io/home-server-project/cockpit-upside:stable
ARG SUPERFILE_PACKAGE_IMAGE=ghcr.io/home-server-project/superfile:stable
ARG VIRTUI_MANAGER_PACKAGE_IMAGE=ghcr.io/home-server-project/virtui-manager:stable


FROM scratch AS ctx

COPY build_files /
COPY system_files /system_files
COPY cosign.pub /cosign.pub


# ============================================================
# Verified Home Server Packages artifacts
# ============================================================

FROM ${UPSIDE_PACKAGE_IMAGE} AS upside-package
FROM ${SUPERFILE_PACKAGE_IMAGE} AS superfile-package
FROM ${VIRTUI_MANAGER_PACKAGE_IMAGE} AS virtui-manager-package


# ============================================================
# Final uCore / uCore HCI image
# ============================================================

FROM ${UCORE_IMAGE}

ARG UCORE_IMAGE
ARG IMAGE_REPOSITORY


RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=upside-package,source=/rpms,target=/upside-rpm \
    --mount=type=bind,from=superfile-package,source=/rpms,target=/superfile-rpm \
    --mount=type=bind,from=virtui-manager-package,source=/rpms,target=/virtui-manager-rpm \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    UCORE_IMAGE="${UCORE_IMAGE}" \
    IMAGE_REPOSITORY="${IMAGE_REPOSITORY}" \
    /ctx/build.sh


RUN bootc container lint
