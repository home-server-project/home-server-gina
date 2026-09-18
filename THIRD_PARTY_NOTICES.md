# Third-party notices

Home Server Gina is licensed under Apache-2.0. Software included from upstream images, Fedora packages, and third-party projects retains its own upstream license and copyright.

## Universal Blue uCore

Home Server Gina builds directly from the Universal Blue uCore LTS and uCore HCI LTS images:

https://github.com/ublue-os/ucore

Universal Blue uCore is itself built on Fedora CoreOS. Home Server Project does not replace or relicense the upstream operating-system content provided by uCore, Fedora CoreOS, Fedora packages, or their dependencies.

## Home Server Packages

UPSide and VirtUI Manager are consumed as verified RPM artifacts from the Home Server Packages repository:

https://github.com/home-server-project/home-server-packages

That repository owns their upstream version tracking, exact source provenance, package build, license retention and Fedora/Enterprise Linux validation.

## UPSide

https://github.com/deviationist/cockpit-upside

UPSide retains its upstream LGPL-2.1-or-later license. Gina installs the verified `cockpit-upside` RPM from Home Server Packages rather than compiling UPSide locally.

## uBlue Brew and Homebrew

Home Server Gina consumes the uBlue Brew bootc integration from:

https://github.com/ublue-os/brew

Each image build resolves the current uBlue Brew image to an exact digest and verifies it with
uBlue's signing key before composition. The integration supplies the official Homebrew bootstrap
payload, systemd units and shell integration used by both Gina variants.

Homebrew itself is maintained upstream at:

https://github.com/Homebrew/brew

## VirtUI Manager

https://github.com/aginies/virtui-manager

VirtUI Manager retains its upstream GPL-3.0-or-later license. Gina HCI installs the verified `virtui-manager` RPM from Home Server Packages. Regular Gina intentionally does not include VirtUI Manager.

## Fedora packages and other upstream software

Packages installed from Fedora/uCore sources, including Network UPS Tools, PowerTOP, NetBird, and their dependencies, retain the licenses and notices provided by their respective upstream projects and packages.

See [`UPSTREAM.md`](UPSTREAM.md) for the primary upstream-project relationship and attribution notes.
