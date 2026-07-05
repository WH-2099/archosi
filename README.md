# archosi

`archosi` is a `mkosi` configuration for building an Arch Linux x86-64 system image.

| Path | Role |
| --- | --- |
| `mkosi/` | Upstream `systemd/mkosi` submodule. |
| `./mkosi-local` | Calls `mkosi/bin/mkosi` from the repository root. |
| `.tmp/` | Created by `mkosi-local` and exported as `TMPDIR`. |

## Configuration

| Area | Value |
| --- | --- |
| Image | Arch Linux rolling x86-64 GPT disk image. |
| Output directory | `mkosi.output/` |
| Default image | `mkosi.output/image.raw.zst` |
| Boot path | UEFI, systemd-boot, UKI. |
| Default security | No Secure Boot, LUKS, verity, or expected PCR signing. |
| Root filesystem | Btrfs subvolume `@` with `noatime,compress=zstd`. |
| ESP | 1G vfat mounted at `/efi`. |
| Root password | `root` |
| Root shell | `/usr/bin/fish` |
| Locale | `en_US.UTF-8` |
| Timezone | `UTC` |
| Official packages | `mkosi.conf.d/10-packages.conf` |
| AUR packages | `mkosi.aur-packages` |
| AUR install script | `mkosi.postinst.d/50-aur.sh.chroot` |
| Runtime root repart config | `mkosi.extra/etc/repart.d/10-root.conf` |
| Encryption profile | `mkosi.profiles/encrypt` |
| Encryption profile security | Secure Boot and LUKS root. |
| Encryption profile root | `Encrypt=key-file` |
| Encryption profile initramfs | mkinitcpio hooks include `sd-encrypt`. |

## Development

| Phase | Action | Command |
| --- | --- | --- |
| Tools | Install base tools | `sudo pacman -S --needed git bash python openssl qemu-base edk2-ovmf` |
| Source | Initialize submodule | `git submodule update --init --recursive` |
| Source | Verify submodule | `git submodule status`<br>`test -x mkosi/bin/mkosi` |
| Hooks | Config file | `prek.toml` |
| Hooks | Install hook | `prek install` |
| Hooks | Run all hooks | `prek run --all-files` |
| Hooks | Install `prek` on Arch Linux | `paru -S --needed prek-bin` |

## Build The Default Image

| Stage | Command | Output |
| --- | --- | --- |
| Inspect | `./mkosi-local summary` | Final configuration summary. |
| Inspect | `./mkosi-local cat-config` | Merged configuration. |
| Build | `./mkosi-local build` | Default image build. |
| Verify | `ls -lh mkosi.output/image.raw.zst` | Compressed raw image. |

## Build The Encrypted Image

| Item | Value |
| --- | --- |
| Profile | `mkosi.profiles/encrypt` |
| Secure Boot key | `mkosi.profiles/encrypt/mkosi.extra/etc/kernel/secure-boot.key` |
| Secure Boot certificate | `mkosi.profiles/encrypt/mkosi.extra/etc/kernel/secure-boot.crt` |
| Git status | Listed in `.gitignore`; do not commit. |
| LUKS passphrase file | `mkosi.profiles/encrypt/mkosi.passphrase` |

Generate a self-signed key and certificate for local testing.

```console
install -d -m 0755 mkosi.profiles/encrypt/mkosi.extra/etc/kernel
openssl req -newkey rsa:4096 -nodes -keyout mkosi.profiles/encrypt/mkosi.extra/etc/kernel/secure-boot.key -new -x509 -sha256 -days 3650 -subj "/CN=archosi Secure Boot/" -out mkosi.profiles/encrypt/mkosi.extra/etc/kernel/secure-boot.crt
chmod 600 mkosi.profiles/encrypt/mkosi.extra/etc/kernel/secure-boot.key
```

Or copy an existing key and certificate.

```console
install -m 0600 secure-boot.key mkosi.profiles/encrypt/mkosi.extra/etc/kernel/secure-boot.key
install -m 0644 secure-boot.crt mkosi.profiles/encrypt/mkosi.extra/etc/kernel/secure-boot.crt
```

Tighten the LUKS passphrase file permissions.

```console
chmod 600 mkosi.profiles/encrypt/mkosi.passphrase
```

| Stage | Command | Output |
| --- | --- | --- |
| Inspect | `./mkosi-local --profile encrypt summary` | Final encryption profile summary. |
| Build | `./mkosi-local --profile encrypt build` | Encrypted image build. |

## Rotate Installed Secrets

| Context | Value |
| --- | --- |
| Build-time state | Deterministic plaintext secrets. |
| Rotation point | After booting the installed system. |

| Order | Action | Command |
| --- | --- | --- |
| 1 | Change root password | `passwd` |
| 2 | Add new LUKS passphrase | `cryptsetup luksAddKey /dev/disk/by-partlabel/ROOT` |
| 3 | Verify new LUKS passphrase | `cryptsetup open --test-passphrase /dev/disk/by-partlabel/ROOT` |
| 4 | Remove deterministic LUKS passphrase | `cryptsetup luksRemoveKey /dev/disk/by-partlabel/ROOT` |

## Bind TPM2 To PCR 7

| Guardrail | Value |
| --- | --- |
| Timing | After Secure Boot is final and the deterministic LUKS passphrase is removed. |
| Recovery | Keep at least one manual LUKS passphrase. |

| Order | Action | Command |
| --- | --- | --- |
| 1 | Enroll TPM2 token | `systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/disk/by-partlabel/ROOT` |
| 2 | Reboot and confirm TPM2 unlock | `systemctl reboot` |

Except for the Secure Boot signing key and certificate, the current build configuration is complete.
