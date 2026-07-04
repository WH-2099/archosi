#!/usr/bin/env bash
set -euo pipefail

rm -f \
    "$BUILDROOT/etc/hostname" \
    "$BUILDROOT/etc/machine-info" \
    "$BUILDROOT/var/lib/systemd/random-seed" \
    "$BUILDROOT/var/lib/systemd/credential.secret" \
    "$BUILDROOT/efi/loader/random-seed"

for path in "$BUILDROOT"/efi/EFI/BOOT/BOOT*.EFI; do
    [[ -e "$path" ]] || continue
    [[ "${path##*/}" == "BOOTX64.EFI" ]] || rm -f "$path"
done

for path in \
    "$BUILDROOT"/efi/EFI/systemd/systemd-boot*.efi \
    "$BUILDROOT"/usr/lib/systemd/boot/efi/systemd-boot*.efi*
do
    [[ -e "$path" ]] || continue
    case "${path##*/}" in
        systemd-bootx64.efi|systemd-bootx64.efi.signed) ;;
        *) rm -f "$path" ;;
    esac
done

rm -rf \
    "$BUILDROOT/var/lib/pacman/sync" \
    "$BUILDROOT/var/cache/pacman/pkg" \
    "$BUILDROOT/var/cache/paru" \
    "$BUILDROOT/root/.cache/paru" \
    "$BUILDROOT/var/tmp/aur-build"
