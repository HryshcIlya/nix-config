# Secrets Management

Secrets are encrypted via [agenix](https://github.com/ryantm/agenix) and stored in a separate
private GitHub repository, referenced as a flake input.

## How It Works

Secrets are encrypted using:

1. **Host SSH key** (`/etc/ssh/ssh_host_ed25519_key`) — for runtime decryption
2. **Recovery key** — stored offline on a backup USB for disaster recovery

The host key is generated locally by OpenSSH, never leaves the host, and is only readable by `root`.
Secrets remain encrypted in the Nix store and are decrypted only when used.

## Standalone Recovery Process

Since this is a single-host configuration, rekeying is done with the **recovery key** stored on a
backup USB, not from another host.

### Rekeying After Fresh Install

This repository (`nix-config`) references the private secrets repo as a flake input (`mysecrets`).
If GitHub SSH access is not available yet, rekey from your backup USB and use a local override for
the first switch.

1. Boot into the minimal system after installation.
2. Ensure host SSH keys persist (this config uses an ephemeral `/`):

   ```bash
   sudo mkdir -p /persistent/etc
   sudo mv /etc/ssh /persistent/etc/
   ```

3. Mount your backup USB with the secrets repo:

   ```bash
   sudo mount /dev/sdb1 /mnt/usb
   cd /mnt/usb/nix-secrets
   ```

4. Update `secrets.nix` recipients:

   ```bash
   cat /persistent/etc/ssh/ssh_host_ed25519_key.pub
   ${EDITOR:-nvim} ./secrets.nix
   ```

5. Rekey with the recovery key:

   ```bash
   nix shell github:ryantm/agenix#agenix
   agenix -r -i ./recovery-key
   ```

6. Commit the changes in the secrets repo (push can be done later).

7. When switching to the full NixOS configuration, override the secrets flake input from USB:

   ```bash
   sudo nixos-rebuild switch --flake ~/nix-config#ai-niri \
     --override-input mysecrets git+file:///mnt/usb/nix-secrets
   ```

Important:

- Do not use `--override-input mysecrets path:...` pointing at a directory that contains
  `recovery-key`. `path:` inputs are copied into `/nix/store` wholesale.

## Adding or Updating Secrets

All operations are performed in the private `nix-secrets` repository.

### Using agenix CLI

```bash
nix shell github:ryantm/agenix#agenix
```

### Creating a New Secret

1. Edit `secrets.nix` to add the new secret:

   ```nix
   let
     host_ai = "ssh-ed25519 AAAA... root@ai";
     recovery_key = "ssh-ed25519 AAAA... User@recovery";
     systems = [ host_ai recovery_key ];
   in
   {
     "./new-secret.age".publicKeys = systems;
   }
   ```

2. Create and encrypt the secret:

   ```bash
   # Using host key (on the running system)
   agenix -e ./new-secret.age -i /etc/ssh/ssh_host_ed25519_key

   # Or using recovery key (from backup USB)
   agenix -e ./new-secret.age -i ./recovery-key
   ```

### Editing an Existing Secret

```bash
agenix -e ./existing-secret.age -i /etc/ssh/ssh_host_ed25519_key
```

## Deploying Secrets

Secrets are automatically decrypted during `nixos-rebuild switch` using the host's SSH key.

In this configuration, when using an ephemeral root with preservation, the key is expected at:

- `/persistent/etc/ssh/ssh_host_ed25519_key`

The configuration in `secrets/nixos.nix` defines which secrets are deployed:

```nix
age.secrets."secret-name" = {
  file = "${mysecrets}/secret-name.age";
  path = "/run/agenix/secret-name";
  mode = "0400";
  owner = "root";
};
```

## Troubleshooting

Check agenix logs:

```bash
journalctl | grep -5 agenix
```

Common issues:

- **"No identity found"** — Host key not in `secrets.nix` or not copied to `/persistent/etc/ssh/`
- **"Failed to decrypt"** — Wrong key or corrupted `.age` file
