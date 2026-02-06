# Install (ai)

From NixOS live ISO.

## 1) Secrets USB + env

```bash
export NIX_CONFIG="experimental-features = nix-command flakes"

SECRETS=$(realpath "/run/media/$USER/Backup/nix-secrets")
```

## 2) Start proxy (required)

Run and keep it open:

```bash
nix run nixpkgs/nixos-unstable#throne
```

## 3) Proxy env (for sudo too)

```bash
proxy_url="http://127.0.0.1:2080"
export http_proxy="$proxy_url" https_proxy="$proxy_url"
export HTTP_PROXY="$http_proxy" HTTPS_PROXY="$https_proxy"
export no_proxy="127.0.0.1,localhost,::1"
export NO_PROXY="$no_proxy"

sudo_env() {
  sudo env \
    NIX_CONFIG="$NIX_CONFIG" \
    http_proxy="$http_proxy" https_proxy="$https_proxy" \
    HTTP_PROXY="$HTTP_PROXY" HTTPS_PROXY="$HTTPS_PROXY" \
    no_proxy="$no_proxy" NO_PROXY="$NO_PROXY" \
    "$@"
}

sudo mkdir -p /run/systemd/system/nix-daemon.service.d
sudo tee /run/systemd/system/nix-daemon.service.d/proxy.conf >/dev/null <<EOF
[Service]
Environment="http_proxy=$http_proxy"
Environment="https_proxy=$https_proxy"
Environment="HTTP_PROXY=$HTTP_PROXY"
Environment="HTTPS_PROXY=$HTTPS_PROXY"
Environment="no_proxy=$no_proxy"
Environment="NO_PROXY=$NO_PROXY"
EOF

sudo systemctl daemon-reload
sudo systemctl restart nix-daemon
```

## 4) Clone config repo

```bash
git clone https://github.com/HryshcIlya/nix-config.git
cd nix-config
```

## 5) Disko (DESTRUCTIVE)

```bash
sudo_env nix run github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  ./hosts/idols-ai/disko.nix
```

## 6) Make `~/nix-config` persistent

```bash
USERNAME=$(nix eval --raw --expr '(import ./vars).username')
TARGET_REPO="/mnt/persistent/home/${USERNAME}/nix-config"

sudo mkdir -p "/mnt/persistent/home/${USERNAME}"
sudo rm -rf "$TARGET_REPO"
sudo cp -a . "$TARGET_REPO"
```

## 7) Create host key + machine-id

```bash
sudo install -d -m 0755 /mnt/persistent/etc
sudo install -d -m 0700 /mnt/persistent/etc/ssh

sudo ssh-keygen -t ed25519 -a 256 -N "" \
  -f /mnt/persistent/etc/ssh/ssh_host_ed25519_key

sudo systemd-machine-id-setup --root=/mnt/persistent --commit
```

## 8) Rekey secrets + commit + push

```bash
USER_HOME="/mnt/persistent/home/${USERNAME}"

sudo install -d -m 0700 -o "$USER" -g users "${USER_HOME}/.ssh"
ssh-keygen -t ed25519 -a 256 -C "${USERNAME}@ai" -N "" -f "${USER_HOME}/.ssh/ai"

cat "${USER_HOME}/.ssh/ai.pub"

eval "$(ssh-agent -s)"
ssh-add "${USER_HOME}/.ssh/ai"

mkdir -p "$SECRETS/keys"
cp /mnt/persistent/etc/ssh/ssh_host_ed25519_key.pub "$SECRETS/keys/ai.pub"

nix shell github:ryantm/agenix#agenix --command \
  agenix -r -i "$SECRETS/recovery-key"

NAME=$(nix eval --raw --expr '(import ./vars).userfullname')
EMAIL=$(nix eval --raw --expr '(import ./vars).useremail')

git -C "$SECRETS" config user.name "$NAME"
git -C "$SECRETS" config user.email "$EMAIL"
git -C "$SECRETS" config gpg.format ssh
git -C "$SECRETS" config user.signingkey "${USER_HOME}/.ssh/ai.pub"
git -C "$SECRETS" config commit.gpgsign true
git -C "$SECRETS" add -A
git -C "$SECRETS" commit -m "rekey secrets for ai"
git -C "$SECRETS" push
```

## 9) Install

```bash
sudo_env bash -lc '
  ulimit -n 524288
  exec nixos-install \
    --root /mnt \
    --flake /mnt/persistent/home/'"$USERNAME"'/nix-config#ai-niri \
    --override-input mysecrets "git+file://'"$SECRETS"'" \
    --no-channel-copy \
    --no-root-password \
    --show-trace
'

sudo nixos-enter --root /mnt -c "chown -R ${USERNAME}:users /persistent/home/${USERNAME}/nix-config"
sudo nixos-enter --root /mnt -c "chown -R ${USERNAME}:users /persistent/home/${USERNAME}/.ssh"
```

## 10) Reboot

```bash
reboot
```
