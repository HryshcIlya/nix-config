{ lib, ... }:
{
  # Or disable the firewall altogether.
  networking.firewall.enable = lib.mkDefault false;
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true;
      # root user is used for remote deployment, so we need to allow it
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false; # disable password login
    };
    openFirewall = true;
  };

  # GitHub's SSH host key (prevents TOFU warning)
  # https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
  programs.ssh.knownHosts."github.com".publicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

  # Add terminfo database of all known terminals to the system profile.
  # https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/modules/config/terminfo.nix
  environment.enableAllTerminfo = true;
}
