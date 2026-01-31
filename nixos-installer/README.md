# NixOS Installation with Disko

This flake provides a minimal NixOS configuration for installing the system on a new machine using
[disko](https://github.com/nix-community/disko) for declarative disk partitioning.

## Disk Layout

The disko configuration ([hosts/idols-ai/disko.nix](/hosts/idols-ai/disko.nix)) creates:

- **ESP**: 630MB EFI System Partition at `/boot`
- **LUKS**: Encrypted root partition with passphrase
  - **BTRFS subvolumes**:
    - `@nix` → `/nix` (compressed, noatime)
    - `@persistent` → `/persistent` (compressed, noatime)
    - `@tmp` → `/tmp` (compressed)
    - `@snapshots` → `/snapshots` (compressed, noatime)
    - `@swap` → `/swap` (16GB swapfile)
- **Root**: tmpfs (stateless)

## Installation Steps

### 1. Boot NixOS Installer

Create a USB install medium from NixOS's official ISO image and boot from it.

### 2. Prepare Environment

```bash
# Enter a shell with required tools
nix shell nixpkgs#git nixpkgs#neovim

# Clone this repository
git clone https://github.com/HryshcIlya/nix-config.git
cd nix-config
```

### 3. Run Disko

There are two supported paths. Pick one and follow it end-to-end:

- Path A (recommended): `disko-install` does partitioning + formatting + NixOS install in one step.
- Path B: run `disko` to partition/mount, then run `nixos-install` yourself.

Path A is simpler and reduces the chance of forgetting a step.

#### Path A: disko-install (Recommended)

```bash
# Format + install in one step (DESTRUCTIVE!)
# Replace /dev/nvme0n1 with your actual disk
sudo nix run github:nix-community/disko#disko-install -- \
  --write-efi-boot-entries \
  --disk main /dev/nvme0n1 \
  --flake ./nixos-installer#ai
```

If you use Path A, you still need to enter the installed system (mounted at `/mnt`) before doing the
preservation step:

```bash
sudo nixos-enter --root /mnt
```

#### Path B: disko + nixos-install

```bash
# Format and mount (DESTRUCTIVE!)
# Replace /dev/nvme0n1 with your actual disk
sudo nix run github:nix-community/disko -- \
  --mode disko \
  --disk main /dev/nvme0n1 \
  ./hosts/idols-ai/disko.nix

cd nixos-installer

# Install NixOS
nixos-install --root /mnt --flake .#ai --no-root-password --show-trace

# Enter the installed system
nixos-enter
```

### 4. Preserve Critical Files

> **CRITICAL**: Do NOT skip this step! The root filesystem is tmpfs and will be cleared on reboot.
> Preservation only creates symlinks — you must copy the actual files!

```bash
# Create persistent target dirs
mkdir -p /persistent/etc

# Copy machine-id and SSH host keys to persistent storage
mv /etc/machine-id /persistent/etc/
mv /etc/ssh /persistent/etc/
```

### 5. Finalize and Reboot

```bash
# Exit and reboot
exit
reboot
```

### 6. Post-Reboot Setup

After rebooting into the minimal system (from `nixos-installer` flake), bootstrap your SSH key,
rekey secrets from USB, and switch to the full system.

Important:

- Do not use `--override-input mysecrets path:...` pointing at a directory that contains
  `recovery-key`. `path:` inputs are copied into `/nix/store` wholesale.
- If you need to override `mysecrets` from USB, use `git+file://...`.

```bash
# Generate a new user SSH key (used for GitHub SSH auth and SSH commit signing)
ssh-keygen -t ed25519 -a 256 -C "User@ai" -f ~/.ssh/ai

# Add to ssh-agent
eval $(ssh-agent)
ssh-add ~/.ssh/ai

# Add the public key to GitHub
cat ~/.ssh/ai.pub
# Go to https://github.com/settings/keys and add the key

# Clone nix-config (public)
git clone https://github.com/HryshcIlya/nix-config.git ~/nix-config

# Mount the USB (adjust device name as needed)
sudo mount /dev/sdb1 /mnt/usb
cd /mnt/usb/nix-secrets

# Add the new host's SSH public key to secrets.nix
cat /persistent/etc/ssh/ssh_host_ed25519_key.pub

# Edit / update recipients
${EDITOR:-nvim} ./secrets.nix

# Rekey all secrets with the recovery key
nix shell github:ryantm/agenix#agenix
agenix -r -i ./recovery-key

# Commit locally (signed with SSH). If you do not have your usual git config yet:
git config --local user.name "HryshcIlya"
git config --local user.email "175040986+HryshcIlya@users.noreply.github.com"
git config --local gpg.format ssh
git config --local user.signingkey ~/.ssh/ai
git config --local commit.gpgsign true
git commit -am "rekey secrets for ai"

# Switch to the full configuration, overriding mysecrets from the USB git repo
cd ~/nix-config
sudo nixos-rebuild switch --flake .#ai-niri \
  --override-input mysecrets git+file:///mnt/usb/nix-secrets

# Clean up
sudo umount /mnt/usb
```

## Enabling Secure Boot

After the system is running, follow the
[lanzaboote Quick Start](https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md)
guide. The secure boot configuration is in
[hosts/idols-ai/secureboot.nix](/hosts/idols-ai/secureboot.nix).

## Changing LUKS Passphrase

```bash
# Test the current passphrase
sudo cryptsetup --verbose open --test-passphrase /dev/nvme0n1p2

# Change the passphrase
sudo cryptsetup luksChangeKey /dev/nvme0n1p2

# Test the new passphrase
sudo cryptsetup --verbose open --test-passphrase /dev/nvme0n1p2
```
