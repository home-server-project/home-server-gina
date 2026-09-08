# Third-party notices

Home Server Gina is licensed under Apache-2.0. Software included from upstream images, Fedora packages, and third-party projects retains its own upstream license and copyright.

## Universal Blue uCore

Home Server Gina builds directly from the Universal Blue uCore LTS and uCore HCI LTS images:

https://github.com/ublue-os/ucore

Universal Blue uCore is itself built on Fedora CoreOS. Home Server Project does not replace or relicense the upstream operating-system content provided by uCore, Fedora CoreOS, Fedora packages, or their dependencies.

## UPSide

https://github.com/deviationist/cockpit-upside

UPSide is built from a pinned upstream release and exact upstream commit in an isolated builder stage. Node.js, npm, Git, and other build dependencies do not remain in the final Gina image.

## Superfile

https://github.com/yorukot/superfile

Superfile is built from a pinned upstream release and exact upstream commit in an isolated builder stage. The upstream license is copied into the final image with the installed `spf` binary.

## VirtUI Manager

https://github.com/aginies/virtui-manager

Home Server Gina HCI packages VirtUI Manager from a pinned upstream release and exact upstream commit. Its upstream license is copied into the image, and its private Python/Textual dependency tree is kept separate from Fedora system Python packages.

## Fedora packages and other upstream software

Packages installed from Fedora/uCore sources, including Network UPS Tools, PowerTOP, btop, fastfetch, Micro, NetBird, and their dependencies, retain the licenses and notices provided by their respective upstream projects and packages.

See [`UPSTREAM.md`](UPSTREAM.md) for the primary upstream-project relationship and attribution notes.
