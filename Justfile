set dotenv-filename := "image-template.env"
set dotenv-load

export image_name := env_var("IMAGE_NAME")
export repository_name := env_var("REPOSITORY_NAME")
export repo_organization := env_var("REPO_ORGANIZATION")
export image_desc := env_var("IMAGE_DESC")
export image_keywords := env_var("IMAGE_KEYWORDS")
export image_logo_url := env_var("IMAGE_LOGO_URL")
export default_tag := env_var("DEFAULT_TAG")
export bib_image := env_var("BIB_IMAGE")

alias build-vm := build-qcow2
alias rebuild-vm := rebuild-qcow2
alias run-vm := run-vm-qcow2

[private]
default:
    @just --list

# Check Just Syntax
[group('Just')]
check:
    #!/usr/bin/env bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	just --unstable --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt --check -f Justfile

# Fix Just Syntax
[group('Just')]
fix:
    #!/usr/bin/env bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	just --unstable --fmt -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt -f Justfile || { exit 1; }

# Clean Repo
[group('Utility')]
clean:
    #!/usr/bin/env bash
    set -eoux pipefail
    touch _build
    find *_build* -exec rm -rf {} \;
    rm -f previous.manifest.json
    rm -f changelog.md
    rm -f output.env
    rm -rf output/

# Sudo Clean Repo
[group('Utility')]
[private]
sudo-clean:
    just sudoif just clean

# sudoif bash function
[group('Utility')]
[private]
sudoif command *args:
    #!/usr/bin/env bash
    function sudoif(){
        if [[ "${UID}" -eq 0 ]]; then
            "$@"
        elif [[ "$(command -v sudo)" && -n "${SSH_ASKPASS:-}" ]] && [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
            sudo --askpass "$@" || exit 1
        elif [[ "$(command -v sudo)" ]]; then
            sudo "$@" || exit 1
        else
            exit 1
        fi
    }
    sudoif {{ command }} {{ args }}

# This Justfile recipe builds a container image using Podman.
#
# Arguments:
#   $target_image - The tag you want to apply to the image (default: $image_name).
#   $tag - The tag for the image (default: $default_tag).
#
# The script constructs the version string using the tag and the current date.
# If the git working directory is clean, it also includes the short SHA of the current HEAD.
#
# just build $target_image $tag
#
# Example usage:
#   just build myimage mytag
#
# This will build an image 'myimage:mytag'
#

# Build the image using the specified parameters
build $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash

    set -euox pipefail

    BUILD_ARGS=()
    LABELS=()

    resolve_package_ref() {
        local image="$1"
        local digest

        podman pull "${image}" >/dev/null
        digest="$(podman image inspect "${image}" | jq -r '.[0].Digest')"
        [[ "${digest}" =~ ^sha256:[0-9a-f]{64}$ ]]
        printf '%s@%s' "${image%:*}" "${digest}"
    }

    # GitHub Actions sets UCORE_IMAGE for each matrix entry.
    # If it is unset, Containerfile uses its normal uCore LTS fallback.
    if [[ -n "${UCORE_IMAGE:-}" ]]; then
        BUILD_ARGS+=(
            "--build-arg"
            "UCORE_IMAGE=${UCORE_IMAGE}"
        )
    fi

    # Resolve the moving Home Server Packages stable channels to exact
    # package artifact digests for this image build.
    UPSIDE_PACKAGE_IMAGE="${UPSIDE_PACKAGE_IMAGE:-$(resolve_package_ref ghcr.io/home-server-project/cockpit-upside:stable)}"
    SUPERFILE_PACKAGE_IMAGE="${SUPERFILE_PACKAGE_IMAGE:-$(resolve_package_ref ghcr.io/home-server-project/superfile:stable)}"
    VIRTUI_MANAGER_PACKAGE_IMAGE="${VIRTUI_MANAGER_PACKAGE_IMAGE:-$(resolve_package_ref ghcr.io/home-server-project/virtui-manager:stable)}"

    BUILD_ARGS+=(
        "--build-arg"
        "UPSIDE_PACKAGE_IMAGE=${UPSIDE_PACKAGE_IMAGE}"
        "--build-arg"
        "SUPERFILE_PACKAGE_IMAGE=${SUPERFILE_PACKAGE_IMAGE}"
        "--build-arg"
        "VIRTUI_MANAGER_PACKAGE_IMAGE=${VIRTUI_MANAGER_PACKAGE_IMAGE}"
    )

    echo "Home Server Packages snapshot:"
    echo "  UPSide:         ${UPSIDE_PACKAGE_IMAGE}"
    echo "  Superfile:      ${SUPERFILE_PACKAGE_IMAGE}"
    echo "  VirtUI Manager: ${VIRTUI_MANAGER_PACKAGE_IMAGE}"

    # Pass the exact final GHCR repository into the image so its
    # container-signature policy trusts the image it actually belongs to.
    IMAGE_REPOSITORY="${IMAGE_REPOSITORY:-ghcr.io/{{ repo_organization }}/${target_image}}"

    BUILD_ARGS+=(
        "--build-arg"
        "IMAGE_REPOSITORY=${IMAGE_REPOSITORY}"
    )

    if [[ -z "$(git status -s)" ]]; then
        GIT_SHA=$(git rev-parse --short HEAD)

        LABELS+=(
            "--label"
            "io.artifacthub.package.readme-url=https://raw.githubusercontent.com/{{ repo_organization }}/{{ repository_name }}/${GIT_SHA}/README.md"
        )
        LABELS+=(
            "--label"
            "org.opencontainers.image.documentation=https://raw.githubusercontent.com/{{ repo_organization }}/{{ repository_name }}/${GIT_SHA}/README.md"
        )
        LABELS+=(
            "--label"
            "org.opencontainers.image.source=https://github.com/{{ repo_organization }}/{{ repository_name }}/blob/${GIT_SHA}/Containerfile"
        )
        LABELS+=(
            "--label"
            "org.opencontainers.image.url=https://github.com/{{ repo_organization }}/{{ repository_name }}/tree/${GIT_SHA}"
        )
    fi

    # Image metadata for https://artifacthub.io/
    LABELS+=(
        "--label"
        "io.artifacthub.package.deprecated=false"
    )
    LABELS+=(
        "--label"
        "io.artifacthub.package.keywords={{ image_keywords }}"
    )
    LABELS+=(
        "--label"
        "io.artifacthub.package.license=Apache-2.0"
    )
    LABELS+=(
        "--label"
        "io.artifacthub.package.logo-url={{ image_logo_url }}"
    )
    LABELS+=(
        "--label"
        "io.artifacthub.package.prerelease=false"
    )
    LABELS+=(
        "--label"
        "org.opencontainers.image.created=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    )
    LABELS+=(
        "--label"
        "org.opencontainers.image.description={{ image_desc }}"
    )
    LABELS+=(
        "--label"
        "org.opencontainers.image.title=${target_image}"
    )
    LABELS+=(
        "--label"
        "org.opencontainers.image.vendor={{ repo_organization }}"
    )

    PODMAN_BUILD_ARGS=(
        "${BUILD_ARGS[@]}"
        "${LABELS[@]}"
        --pull=newer
        --tag "${target_image}:${tag}"
        --file Containerfile
    )

    podman build "${PODMAN_BUILD_ARGS[@]}" .

# Split the image into RPM-aware layers for smaller updates.
ostree-rechunk $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash

    set -xeuo pipefail

    # Use the already-built local image to avoid pulling from a remote registry
    RPM_OSTREE_CHUNKER_IMAGE="localhost/${target_image}:${tag}"

    # Preserve the upstream bootc version label when rebuilding from --rootfs.
    IMAGE_VERSION="$(
        podman inspect "${target_image}:${tag}" \
            | jq -r '.[0].Config.Labels["org.opencontainers.image.version"] // empty'
    )"

    if [[ -z "${IMAGE_VERSION}" ]]; then
        echo "org.opencontainers.image.version is missing before rechunking."
        exit 1
    fi

    echo "Preserving image version: ${IMAGE_VERSION}"

    GRAPHROOT="$(podman info --format '{{ '{{.Store.GraphRoot}}' }}')"

    podman run --rm --pull=never --privileged \
      --mount=type=image,src="${target_image}:${tag}",target=/rpm-ostree \
      --mount=type=bind,src=${GRAPHROOT},target=/run/host-container-storage,rw \
      --mount=type=tmpfs,target=/run/rpm-ostree-storage \
      --entrypoint /usr/bin/rpm-ostree \
      "${RPM_OSTREE_CHUNKER_IMAGE}" \
      compose build-chunked-oci \
      --max-layers 127 \
      --format-version=2 \
      --bootc \
      --label "org.opencontainers.image.version=${IMAGE_VERSION}" \
      --rootfs /rpm-ostree \
      --output "containers-storage:[overlay@/run/host-container-storage+/run/rpm-ostree-storage]localhost/${target_image}:${tag}"

    OCI_LAYER_LIMIT="${OCI_LAYER_LIMIT:-128}"
    layer_count="$(
        podman image inspect "${target_image}:${tag}" \
            | jq -r '.[0].RootFS.Layers | length'
    )"

    [[ "${layer_count}" =~ ^[0-9]+$ ]]
    if (( layer_count > OCI_LAYER_LIMIT )); then
        echo "ERROR: rechunked image has ${layer_count} layers; OCI maximum is ${OCI_LAYER_LIMIT}" >&2
        exit 1
    fi

    echo "Rechunked image layers: ${layer_count} / OCI max ${OCI_LAYER_LIMIT} (RPM chunk target 127)"

    if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
        {
            echo "### ${target_image} rechunking"
            echo
            echo "- Rechunked OCI layers: ${layer_count} / ${OCI_LAYER_LIMIT} max"
            echo "- RPM/OSTree chunk target: 127"
        } >> "${GITHUB_STEP_SUMMARY}"
    fi

# Generate Default Tag
[group('Utility')]
generate-default-tag $tag=default_tag:
    #!/usr/bin/env bash
    set -eoux pipefail

    echo "${tag}"

# Generate Tags
[group('Utility')]
generate-build-tags $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash
    set -eoux pipefail

    DATE=$(date +%Y%m%d)
    BUILD_TAGS=()
    if [[ -z "$(git status -s)" ]]; then
        GIT_SHA=$(git rev-parse --short HEAD)
        BUILD_TAGS+=("${tag}-${GIT_SHA}")
        BUILD_TAGS+=("${tag}-${DATE}-${GIT_SHA}")
        BUILD_TAGS+=("${DATE}-${GIT_SHA}")
    fi

    BUILD_TAGS+=("${DATE}")
    BUILD_TAGS+=("${tag}")
    BUILD_TAGS+=("${tag}-${DATE}")

    echo "${BUILD_TAGS[@]}"

# Tag Images
[group('Utility')]
tag-images $target_image=image_name $tag=default_tag tags="":
    #!/usr/bin/env bash
    set -eoux pipefail

    # Get Image, and untag
    IMAGE=$(podman inspect ${target_image}:${tag} | jq -r .[].Id)
    podman untag ${IMAGE}

    # Tag Image
    for tag in {{ tags }}; do
        podman tag $IMAGE "${target_image}:${tag}"
    done

    # Show Images
    podman images

# Image Name
[group('Utility')]
[private]
image_name $target_image=image_name:
    #!/usr/bin/env bash
    set -eoux pipefail

    echo "${image_name}"

# Command: _rootful_load_image
# Description: This script checks if the current user is root or running under sudo. If not, it attempts to resolve the image tag using podman inspect.
#              If the image is found, it loads it into rootful podman. If the image is not found, it pulls it from the repository.
#
# Parameters:
#   $target_image - The name of the target image to be loaded or pulled.
#   $tag - The tag for the image (default: $default_tag).
#
# Example usage:
#   _rootful_load_image my_image latest
#
# Steps:
# 1. Check if the script is already running as root or under sudo
# 2. Check if target image is in the non-root podman container storage)
# 3. If the image is found, load it into rootful podman using podman scp.
# 4. If the image is not found, pull it from the repository.

_rootful_load_image $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash
    set -eoux pipefail

    # Check if already root or running under sudo
    if [[ -n "${SUDO_USER:-}" || "${UID}" -eq "0" ]]; then
        echo "Already root or running under sudo, no need to load image from user podman."
        exit 0
    fi

    # Try to resolve the image tag using podman inspect
    set +e
    resolved_tag=$(podman inspect -t image "${target_image}:${tag}" | jq -r '.[].RepoTags.[0]')
    return_code=$?
    set -e

    USER_IMG_ID=$(podman images --filter reference="${target_image}:${tag}" --format "'{{ '{{.ID}}' }}'")

    if [[ $return_code -eq 0 ]]; then
        # If the image is found, load it into rootful podman
        ID=$(just sudoif podman images --filter reference="${target_image}:${tag}" --format "'{{ '{{.ID}}' }}'")
        if [[ "$ID" != "$USER_IMG_ID" ]]; then
            # If the image ID is not found or different from user, copy the image from user podman to root podman
            COPYTMP=$(mktemp -p "${PWD}" -d -t _build_podman_scp.XXXXXXXXXX)
            just sudoif TMPDIR=${COPYTMP} podman image scp ${UID}@localhost::"${target_image}:${tag}" root@localhost::"${target_image}:${tag}"
            rm -rf "${COPYTMP}"
        fi
    else
        # If the image is not found, pull it from the repository
        just sudoif podman pull "${target_image}:${tag}"
    fi

# Build a bootc bootable image using Bootc Image Builder (BIB)
# Converts a container image to a bootable image
# Parameters:
#   target_image: The name of the image to build (ex. localhost/fedora)
#   tag: The tag for the image (ex. latest)
#   type: The type of image to build (ex. qcow2, raw, iso)
#   config: The configuration file to use for the build (default: disk_config/disk.toml)

# Example: just _rebuild-bib localhost/fedora latest qcow2 disk_config/disk.toml
_build-bib $target_image $tag $type $config: (_rootful_load_image target_image tag)
    #!/usr/bin/env bash
    set -euo pipefail

    args="--type ${type} "
    args+="--use-librepo=True "
    args+="--rootfs=btrfs"

    BUILDTMP=$(mktemp -p "${PWD}" -d -t _build-bib.XXXXXXXXXX)

    sudo podman run \
      --rm \
      -it \
      --privileged \
      --pull=newer \
      --net=host \
      --security-opt label=type:unconfined_t \
      -v $(pwd)/${config}:/config.toml:ro \
      -v $BUILDTMP:/output \
      -v /var/lib/containers/storage:/var/lib/containers/storage \
      "${bib_image}" \
      ${args} \
      "${target_image}:${tag}"

    mkdir -p output
    sudo mv -f $BUILDTMP/* output/
    sudo rmdir $BUILDTMP
    sudo chown -R $USER:$USER output/

# Podman builds the image from the Containerfile and creates a bootable image
# Parameters:
#   target_image: The name of the image to build (ex. localhost/fedora)
#   tag: The tag for the image (ex. latest)
#   type: The type of image to build (ex. qcow2, raw, iso)
#   config: The configuration file to use for the build (deafult: disk_config/disk.toml)

# Example: just _rebuild-bib localhost/fedora latest qcow2 disk_config/disk.toml
_rebuild-bib $target_image $tag $type $config: (build target_image tag) && (_build-bib target_image tag type config)

# Build a QCOW2 virtual machine image
[group('Build Virtal Machine Image')]
build-qcow2 $target_image=("localhost/" + image_name) $tag=default_tag: && (_build-bib target_image tag "qcow2" "disk_config/disk.toml")

# Build a RAW virtual machine image
[group('Build Virtal Machine Image')]
build-raw $target_image=("localhost/" + image_name) $tag=default_tag: && (_build-bib target_image tag "raw" "disk_config/disk.toml")

# Build an ISO virtual machine image
[group('Build Virtal Machine Image')]
build-iso $target_image=("localhost/" + image_name) $tag=default_tag: && (_build-bib target_image tag "iso" "disk_config/iso.toml")

# Rebuild a QCOW2 virtual machine image
[group('Build Virtal Machine Image')]
rebuild-qcow2 $target_image=("localhost/" + image_name) $tag=default_tag: && (_rebuild-bib target_image tag "qcow2" "disk_config/disk.toml")

# Rebuild a RAW virtual machine image
[group('Build Virtal Machine Image')]
rebuild-raw $target_image=("localhost/" + image_name) $tag=default_tag: && (_rebuild-bib target_image tag "raw" "disk_config/disk.toml")

# Rebuild an ISO virtual machine image
[group('Build Virtal Machine Image')]
rebuild-iso $target_image=("localhost/" + image_name) $tag=default_tag: && (_rebuild-bib target_image tag "iso" "disk_config/iso.toml")

# Run a virtual machine with the specified image type and configuration
_run-vm $target_image $tag $type $config:
    #!/usr/bin/env bash
    set -eoux pipefail

    # Determine the image file based on the type
    image_file="output/${type}/disk.${type}"
    if [[ $type == iso ]]; then
        image_file="output/bootiso/install.iso"
    fi

    # Build the image if it does not exist
    if [[ ! -f "${image_file}" ]]; then
        just "build-${type}" "$target_image" "$tag"
    fi

    # Determine an available port to use
    port=8006
    while grep -q :${port} <<< $(ss -tunalp); do
        port=$(( port + 1 ))
    done
    echo "Using Port: ${port}"
    echo "Connect to http://localhost:${port}"

    # Set up the arguments for running the VM
    run_args=()
    run_args+=(--rm --privileged)
    run_args+=(--pull=newer)
    run_args+=(--publish "127.0.0.1:${port}:8006")
    run_args+=(--env "CPU_CORES=4")
    run_args+=(--env "RAM_SIZE=8G")
    run_args+=(--env "DISK_SIZE=64G")
    run_args+=(--env "TPM=Y")
    run_args+=(--env "GPU=Y")
    run_args+=(--device=/dev/kvm)
    run_args+=(--volume "${PWD}/${image_file}":"/boot.${type}")
    run_args+=(docker.io/qemux/qemu)

    # Run the VM and open the browser to connect
    (sleep 30 && xdg-open http://localhost:"$port") &
    podman run "${run_args[@]}"

# Run a virtual machine from a QCOW2 image
[group('Run Virtal Machine')]
run-vm-qcow2 $target_image=("localhost/" + image_name) $tag=default_tag: && (_run-vm target_image tag "qcow2" "disk_config/disk.toml")

# Run a virtual machine from a RAW image
[group('Run Virtal Machine')]
run-vm-raw $target_image=("localhost/" + image_name) $tag=default_tag: && (_run-vm target_image tag "raw" "disk_config/disk.toml")

# Run a virtual machine from an ISO
[group('Run Virtal Machine')]
run-vm-iso $target_image=("localhost/" + image_name) $tag=default_tag: && (_run-vm target_image tag "iso" "disk_config/iso.toml")

# Run a virtual machine using systemd-vmspawn
[group('Run Virtal Machine')]
spawn-vm rebuild="0" type="qcow2" ram="6G":
    #!/usr/bin/env bash

    set -euo pipefail

    [ "{{ rebuild }}" -eq 1 ] && echo "Rebuilding the ISO" && just build-vm {{ rebuild }} {{ type }}

    systemd-vmspawn \
      -M "bootc-image" \
      --console=gui \
      --cpus=2 \
      --ram=$(echo {{ ram }}| numfmt --from=iec) \
      --network-user-mode \
      --vsock=false --pass-ssh-key=false \
      -i ./output/**/*.{{ type }}
