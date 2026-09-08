<p align="center">
  <img src="https://raw.githubusercontent.com/home-server-project/.github/main/logo/banner-navy-mid.png" alt="Home Server Project banner">
</p>

# Home Server Gina

[![LTS build](https://github.com/home-server-project/home-server-gina/actions/workflows/build.yml/badge.svg)](https://github.com/home-server-project/home-server-gina/actions/workflows/build.yml)

> [!IMPORTANT]
> Home Server Gina is a thin downstream Home Server Project image layer. It is **not a fork of Fedora CoreOS or Universal Blue uCore**, and it does not replace their operating-system engineering.
>
> The kernel, Fedora CoreOS base, bootc/rpm-ostree stack, storage stack, virtualization stack, container stack, drivers and core uCore functionality remain upstream.

Home Server Gina is built on [Universal Blue uCore](https://github.com/ublue-os/ucore) LTS, with a deliberately small home-server administration and UPS tooling layer added on top.

## Upstream foundation

We chose Universal Blue uCore deliberately.

Universal Blue does excellent work building practical uCore server and HCI images on top of [Fedora CoreOS](https://fedoraproject.org/coreos/), including the LTS image line used directly by Gina.

Fedora CoreOS remains the atomic, image-based operating-system foundation underneath uCore. Home Server Project stays intentionally close to that upstream work and adds only a small set of host-side administration, diagnostics, UPS and convenience tools rather than trying to become a separate all-in-one server distribution.

```text
Fedora CoreOS
      |
      v
Universal Blue uCore / uCore HCI LTS
      |
      v
Home Server Gina / Gina HCI
      |
      v
small Home Server Project tool layer
```

Home Server Gina is an independent community project and is not affiliated with or endorsed by Universal Blue or the Fedora Project.

## Other Home Server Project OS

Prefer a slower-moving Enterprise Linux 10 foundation with a broader built-in home-server toolkit? See [Home Server Rose](https://github.com/home-server-project/home-server-rose).

Rose and Gina follow the same Home Server Project philosophy, but use different upstream foundations:

- **Rose** — AlmaLinux OS 10 / Enterprise Linux foundation, broader built-in host layer
- **Gina** — Fedora CoreOS + Universal Blue uCore LTS foundation, thinner downstream layer and newer LTS kernel line

## Images

The repository builds two image variants in parallel.

| Variant | LTS image | Upstream base | Purpose |
|---|---|---|---|
| Home Server Gina | `ghcr.io/home-server-project/home-server-gina:lts` | `ghcr.io/ublue-os/ucore:lts` | Thin home-server administration layer on uCore LTS |
| Home Server Gina HCI | `ghcr.io/home-server-project/home-server-gina-hci:lts` | `ghcr.io/ublue-os/ucore-hci:lts` | Same Home Server layer on the upstream uCore HCI LTS image, plus Gina's HCI-only utility |

### Release channels

| Channel | Moving tag | Source branch | Scheduled rebuild |
|---|---|---|---|
| LTS | `:lts` | `main` | Weekly on Saturday (UTC) |

Normal repository changes and manual workflow runs can also build the images.

## What is included

Gina deliberately keeps its custom layer small, so the individual tools remain useful to show directly.

| Tool | Purpose |
|---|---|
| NUT / NUT client | Native UPS monitoring and shutdown integration |
| UPSide | Cockpit interface for NUT |
| PowerTOP | Power diagnostics |
| NetBird | Alternative mesh-VPN client alongside upstream Tailscale |
| Micro | Friendly terminal text editor |
| Superfile | Terminal file manager (`spf`) |
| btop | System/resource monitoring |
| fastfetch | Quick system information |
| VirtUI Manager | Terminal libvirt/QEMU virtual machine manager — Gina HCI only |

The Home Server Project software layer is declared in [`build_files/software.env`](build_files/software.env). Fedora packages follow the Fedora/uCore package sources. External projects such as UPSide, Superfile and VirtUI Manager are pinned to a release version and exact upstream commit, with Renovate monitoring those versions for updates.

Everything else stays as close as possible to upstream uCore.

Applications such as Jellyfin, Plex, databases, media automation, download stacks, application servers and large monitoring platforms belong in containers rather than being baked into Gina.

## UPS and power

Native UPS integration is one of the main reasons this small downstream layer exists.

Gina includes NUT, the NUT client, UPSide and PowerTOP, but no machine-specific UPS configuration is baked into the image. UPS model, USB identity, credentials, shutdown thresholds and battery policy remain local to each server.

A system with no UPS should work normally.

PowerTOP is included for diagnostics only. Gina does not automatically enable `powertop --auto-tune`.

For UPSide configuration and troubleshooting, see [`docs/nut-upside-coreos-troubleshooting.md`](docs/nut-upside-coreos-troubleshooting.md).

## Networking

Upstream uCore already includes Tailscale. Gina additionally provides the native [NetBird](https://github.com/netbirdio/netbird) client for users who prefer NetBird or operate their own NetBird infrastructure.

No NetBird account, setup key or management-server configuration is included. NetBird is installed but deliberately left disabled and unconfigured.

## Kernel scope

Gina does not maintain, replace or independently select a kernel.

The project builds only from the upstream **uCore LTS** and **uCore HCI LTS** image lines. The kernel delivered by those upstream LTS images is the kernel Gina receives.

Kernel regressions and kernel issues remain upstream issues.

## Installation

### Fresh install

For a fresh installation, use the [Home Server Gina Builder](https://github.com/home-server-project/home-server-gina-builder) to create a personalized [Home Server Installer](https://github.com/home-server-project/home-server-installer) ISO with your SSH public key.

The current V1 installer exposes five LTS targets:

- **Home Server Gina LTS**
- **Home Server Gina HCI LTS**
- **uCore Minimal LTS**
- **uCore LTS**
- **uCore HCI LTS**

The installer downloads, verifies and installs the selected image directly as the first bootable deployment. An internet connection is required during the normal installation path.

Use the Builder README for ISO creation instructions and the Installer README for installation behavior, storage layout, SSH access and current testing notes.

### Existing compatible bootc/uCore installation

For Home Server Gina:

```bash
sudo bootc switch ghcr.io/home-server-project/home-server-gina:lts
```

For Home Server Gina HCI:

```bash
sudo bootc switch ghcr.io/home-server-project/home-server-gina-hci:lts
```

Then reboot.

## Updates

The scheduled GitHub Actions workflow rebuilds Gina weekly from the current upstream uCore LTS images. Repository changes and manual workflow runs can also build the images.

Fedora/uCore system content follows the upstream base images. Home Server Project additions declared in `build_files/software.env` are maintained separately; external project versions are tracked by Renovate.

The build then rechunks, publishes and signs the resulting images.

## Image signing and releases

Published images are signed with Cosign using the Home Server Project signing key.

The workflow signs the exact image digest published to GHCR. Successful builds also publish immutable tags in the existing format:

```text
lts-YYYYMMDD-<git-sha>
```

A GitHub Release is created only after both the regular and HCI images are available with matching release tags.

## Issue policy

Open an issue in this repository when the problem is caused by something Home Server Gina adds or integrates.

Examples:

- NUT or another Gina-added package failed to install
- UPSide, NetBird, Superfile or another added utility is missing or packaged incorrectly
- VirtUI Manager integration is broken in Gina HCI
- the Home Server Project build workflow fails
- Gina image signing or publication is broken

If the same problem happens on plain upstream uCore or Fedora CoreOS, report it to the project that maintains that component.

Kernel regressions, hardware drivers, Fedora CoreOS problems, bootc/rpm-ostree problems, Podman, Cockpit itself, libvirt/KVM and core uCore services remain upstream responsibilities.

<details>
<summary><strong>Upstream issue trackers</strong></summary>

- [Universal Blue uCore](https://github.com/ublue-os/ucore/issues)
- [Fedora CoreOS](https://github.com/coreos/fedora-coreos-tracker/issues)
- [bootc](https://github.com/bootc-dev/bootc/issues)
- [rpm-ostree](https://github.com/coreos/rpm-ostree/issues)
- [Cockpit](https://github.com/cockpit-project/cockpit/issues)
- [Podman](https://github.com/containers/podman/issues)
- [Network UPS Tools](https://github.com/networkupstools/nut/issues)
- [UPSide](https://github.com/deviationist/cockpit-upside/issues)
- [NetBird](https://github.com/netbirdio/netbird/issues)
- [Micro](https://github.com/micro-editor/micro/issues)
- [Superfile](https://github.com/yorukot/superfile/issues)
- [VirtUI Manager](https://github.com/aginies/virtui-manager/issues)

</details>

## Feature requests

Small host-side administration, diagnostic or hardware-management utilities can be considered for Gina.

Large applications and services that naturally belong in containers should stay out of the OS image. The goal is to keep the Gina-specific layer small and understandable.

## Architectures

Currently published and tested by this project:

```text
x86_64 / amd64
```

ARM64 is not currently published by Gina.

## Upstream and references

<details>
<summary><strong>Project and upstream links</strong></summary>

- [Fedora CoreOS](https://fedoraproject.org/coreos/)
- [Universal Blue uCore](https://github.com/ublue-os/ucore)
- [Universal Blue image-template](https://github.com/ublue-os/image-template)
- [Home Server Rose](https://github.com/home-server-project/home-server-rose)
- [Home Server Project](https://github.com/home-server-project)
- [Home Server Gina Builder](https://github.com/home-server-project/home-server-gina-builder)
- [Home Server Installer](https://github.com/home-server-project/home-server-installer)

</details>

See [`UPSTREAM.md`](UPSTREAM.md) for upstream attribution and relationship details.

## License

Apache-2.0. Third-party software included in the images retains its own upstream license. See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for direct third-party additions and notices.
