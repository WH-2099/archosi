# archosi

`archosi` is a `mkosi` configuration for building an Arch Linux x86-64 system image.

The `mkosi/` directory is the upstream `systemd/mkosi` submodule.

Use `./mkosi-local` from the repository root to call `mkosi/bin/mkosi` from that submodule.

`mkosi-local` creates `.tmp/` in the repository root and exports it as `TMPDIR`.

## Configuration

The default image is an Arch Linux rolling x86-64 GPT disk image.

Build outputs are written to `mkosi.output/`.

The default image file is `mkosi.output/image.raw.zst`.

The boot path uses UEFI, systemd-boot, and UKI.

The default profile does not enable Secure Boot, LUKS, verity, or expected PCR signing.

The root filesystem uses Btrfs with `@` as the default subvolume and `noatime,compress=zstd` as mount options.

The ESP is a 1G vfat partition mounted at `/efi`.

The default root password is `root`.

The root shell is `/usr/bin/fish`.

The system locale is `en_US.UTF-8`.

The timezone is `UTC`.

`mkosi.conf.d/10-packages.conf` defines the official package list.

`mkosi.aur-packages` defines the AUR package list.

`mkosi.postinst.d/50-aur.sh.chroot` builds and installs AUR packages inside the image.

`mkosi.extra/etc/repart.d/10-root.conf` keeps a runtime root partition definition for manual `systemd-repart`.

`mkosi.profiles/encrypt` is the encryption profile.

The encryption profile enables Secure Boot and LUKS root.

The encryption profile root partition uses `Encrypt=key-file`.

The encryption profile mkinitcpio hooks also enable `sd-encrypt`.

## Development

Install the base tools.

```console
sudo pacman -S --needed git bash python openssl qemu-base edk2-ovmf
```

Initialize the submodule.

```console
git submodule update --init --recursive
```

Verify that the submodule is ready.

```console
git submodule status
test -x mkosi/bin/mkosi
```

This repository uses `prek.toml` for pre-commit hooks.

Install the pre-commit hook.

```console
prek install
```

Run all hooks manually.

```console
prek run --all-files
```

If `prek` is not installed yet, install the AUR package on Arch Linux.

```console
paru -S --needed prek-bin
```

## Build The Default Image

Show the final configuration summary.

```console
./mkosi-local summary
```

Show the merged configuration.

```console
./mkosi-local cat-config
```

Build the default image.

```console
./mkosi-local build
```

Check the output after the build finishes.

```console
ls -lh mkosi.output/image.raw.zst
```

## Build The Encrypted Image

The encryption profile needs a local Secure Boot signing key and certificate.

These paths are listed in `.gitignore`.

Do not commit these files to the repository.

Put the files at the following paths.

```text
mkosi.profiles/encrypt/mkosi.extra/etc/kernel/secure-boot.key
mkosi.profiles/encrypt/mkosi.extra/etc/kernel/secure-boot.crt
```

For local testing, generate a self-signed key and certificate.

```console
install -d -m 0755 mkosi.profiles/encrypt/mkosi.extra/etc/kernel
openssl req -newkey rsa:4096 -nodes -keyout mkosi.profiles/encrypt/mkosi.extra/etc/kernel/secure-boot.key -new -x509 -sha256 -days 3650 -subj "/CN=archosi Secure Boot/" -out mkosi.profiles/encrypt/mkosi.extra/etc/kernel/secure-boot.crt
chmod 600 mkosi.profiles/encrypt/mkosi.extra/etc/kernel/secure-boot.key
```

If you already have your own key and certificate, copy them to the same paths.

```console
install -m 0600 secure-boot.key mkosi.profiles/encrypt/mkosi.extra/etc/kernel/secure-boot.key
install -m 0644 secure-boot.crt mkosi.profiles/encrypt/mkosi.extra/etc/kernel/secure-boot.crt
```

Tighten the LUKS passphrase file permissions.

```console
chmod 600 mkosi.profiles/encrypt/mkosi.passphrase
```

Show the final encryption profile summary.

```console
./mkosi-local --profile encrypt summary
```

Build the encrypted image.

```console
./mkosi-local --profile encrypt build
```

## Rotate Installed Secrets

The current image intentionally uses deterministic plaintext secrets during the build.

Rotate them after booting the installed system.

Change the root password.

```console
passwd
```

Add a new LUKS passphrase for the root partition.

```console
cryptsetup luksAddKey /dev/disk/by-partlabel/ROOT
```

Verify that the new LUKS passphrase works.

```console
cryptsetup open --test-passphrase /dev/disk/by-partlabel/ROOT
```

Remove the old deterministic LUKS passphrase.

```console
cryptsetup luksRemoveKey /dev/disk/by-partlabel/ROOT
```

## Bind TPM2 To PCR 7

Do this after Secure Boot is in its final enrolled state and the deterministic LUKS passphrase has been removed.

Keep at least one manual LUKS passphrase as the recovery path.

Enroll a TPM2 token sealed to PCR 7 for the root partition.

```console
systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/disk/by-partlabel/ROOT
```

Reboot once and confirm the root partition unlocks through TPM2.

```console
systemctl reboot
```

Except for the Secure Boot signing key and certificate, the current build configuration is complete.
