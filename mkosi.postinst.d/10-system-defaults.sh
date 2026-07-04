#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$BUILDROOT/boot" "$BUILDROOT/efi" "$BUILDROOT/etc"
ln -sfn ../run/systemd/resolve/stub-resolv.conf "$BUILDROOT/etc/resolv.conf"
