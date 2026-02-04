# Install (ai)

This installs the full system in one pass.

## 1) Secrets USB

Mount the USB via Thunar, then set the path:

```bash
SECRETS=$(realpath /run/media/$USER/Backup/nix-secrets)
ls -la "$SECRETS"

# Enable nix-command + flakes on the ISO.
export NIX_CONFIG="experimental-features = nix-command flakes"
```

## 2) Optional proxy (if build hangs on cache.numtide.com)

Start Throne and enable HTTP proxy at `127.0.0.1:2080`:

```bash
nix run nixpkgs/nixos-unstable#throne
```

Then export proxy and restart `nix-daemon`:

```bash
proxy_url="http://127.0.0.1:2080"
no_proxy="127.0.0.1,localhost,::1"

export http_proxy="$proxy_url" https_proxy="$proxy_url"
export HTTP_PROXY="$proxy_url" HTTPS_PROXY="$proxy_url"
export no_proxy="$no_proxy" NO_PROXY="$no_proxy"

sudo mkdir -p /run/systemd/system/nix-daemon.service.d
sudo tee /run/systemd/system/nix-daemon.service.d/proxy.conf >/dev/null <<EOF
[Service]
Environment="http_proxy=$proxy_url"
Environment="https_proxy=$proxy_url"
Environment="HTTP_PROXY=$proxy_url"
Environment="HTTPS_PROXY=$proxy_url"
Environment="no_proxy=$no_proxy"
Environment="NO_PROXY=$no_proxy"
EOF

sudo systemctl daemon-reload
sudo systemctl restart nix-daemon
```

## 3) Clone the repo

```bash
git clone https://github.com/HryshcIlya/nix-config.git
cd nix-config
```

## 4) Disko (DESTRUCTIVE)

```bash
sudo env NIX_CONFIG="$NIX_CONFIG" nix run github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  ./hosts/idols-ai/disko.nix

# Enable swap on the target disk early.
sudo swapon /mnt/swap/swapfile
```

## 5) Install NixOS (recommended, disk-backed)

Use `nixos-install --flake` so the build happens in `/mnt` (avoids filling ISO RAM).

```bash
sudo env NIX_CONFIG="$NIX_CONFIG" nixos-install \
  --root /mnt \
  --flake .#ai-niri \
  --override-input mysecrets "git+file://${SECRETS}" \
  --no-root-password \
  --show-trace
```

## 6) Create host keys + machine-id in the target

```bash
sudo nixos-enter --root /mnt

ssh-keygen -A
mkdir -p /persistent/etc/ssh
cp -a /etc/ssh/. /persistent/etc/ssh/

systemd-machine-id-setup --root=/persistent --commit

exit
```

## 7) Create user SSH key

```bash
USERNAME=$(nix eval --raw --expr '(import ./vars).username')
USER_HOME="/mnt/persistent/home/${USERNAME}"

sudo mkdir -p "${USER_HOME}/.ssh"
sudo ssh-keygen -t ed25519 -a 256 -C "${USERNAME}@ai" -f "${USER_HOME}/.ssh/ai"
sudo chmod 700 "${USER_HOME}/.ssh"
sudo chmod 600 "${USER_HOME}/.ssh/ai"
sudo chmod 644 "${USER_HOME}/.ssh/ai.pub"
sudo chown -R "${USERNAME}:users" "${USER_HOME}/.ssh"

eval $(ssh-agent)
ssh-add "${USER_HOME}/.ssh/ai"

cat "${USER_HOME}/.ssh/ai.pub"
```

Add the public key to GitHub when convenient.

## 8) Rekey secrets (on the ISO)

```bash
cd "$SECRETS"
mkdir -p keys
cp /mnt/persistent/etc/ssh/ssh_host_ed25519_key.pub ./keys/ai.pub

nix shell github:ryantm/agenix#agenix --command \
  agenix -r -i ./recovery-key

git -C "$SECRETS" config user.name "HryshcIlya"
git -C "$SECRETS" config user.email "175040986+HryshcIlya@users.noreply.github.com"
git -C "$SECRETS" config gpg.format ssh
git -C "$SECRETS" config user.signingkey "${USER_HOME}/.ssh/ai.pub"
git -C "$SECRETS" config commit.gpgsign true
git -C "$SECRETS" add -A
git -C "$SECRETS" commit -m "rekey secrets for ai"
```

## 9) Reboot

```bash
reboot
```
