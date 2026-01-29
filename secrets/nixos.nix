{
  lib,
  config,
  pkgs,
  agenix,
  mysecrets,
  myvars,
  ...
}:
with lib;
let
  cfg = config.modules.secrets;

  noaccess = {
    mode = "0000";
    owner = "root";
  };
  high_security = {
    mode = "0500";
    owner = "root";
  };
  user_readable = {
    mode = "0500";
    owner = myvars.username;
  };
in
{
  imports = [
    agenix.nixosModules.default
  ];

  options.modules.secrets = {
    desktop.enable = mkEnableOption "NixOS Secrets for Desktops";

    preservation.enable = mkEnableOption "whether use preservation and ephemeral root file system";
  };

  config = mkIf cfg.desktop.enable (mkMerge [
    {
      environment.systemPackages = [
        agenix.packages."${pkgs.stdenv.hostPlatform.system}".default
      ];

      # if you changed this key, you need to regenerate all encrypt files from the decrypt contents!
      age.identityPaths =
        if cfg.preservation.enable then
          [
            # To decrypt secrets on boot, this key should exists when the system is booting,
            # so we should use the real key file path(prefixed by `/persistent/`) here, instead of the path mounted by preservation.
            "/persistent/etc/ssh/ssh_host_ed25519_key" # Linux
          ]
        else
          [
            "/etc/ssh/ssh_host_ed25519_key"
          ];

      # secrets that are used by all nixos hosts
      age.secrets = {
        "nix-access-tokens" = {
          file = "${mysecrets}/nix-access-tokens.age";
        }
        # access-token needs to be readable by the user running the `nix` command
        // user_readable;
      };
    }

    {
      age.secrets = {
        # ---------------------------------------------
        # no one can read/write this file, even root.
        # ---------------------------------------------

        # .age means the decrypted file is still encrypted by age(via a passphrase)
        "ryan4yin-gpg-subkeys.priv.age" = {
          file = "${mysecrets}/ryan4yin-gpg-subkeys-2024-01-27.priv.age.age";
        }
        // noaccess;

        # ---------------------------------------------
        # only root can read this file.
        # ---------------------------------------------

        "wg-business.conf" = {
          file = "${mysecrets}/wg-business.conf.age";
        }
        // high_security;

        "rclone.conf" = {
          file = "${mysecrets}/rclone.conf.age";
        }
        // high_security;

        # alias-for-work
        "alias-for-work.nushell" = {
          file = "${mysecrets}/alias-for-work.nushell.age";
        }
        // user_readable;
      };

      # place secrets in /etc/
      environment.etc = {
        # wireguard config used with `wg-quick up wg-business`
        "wireguard/wg-business.conf" = {
          source = config.age.secrets."wg-business.conf".path;
        };

        "agenix/rclone.conf" = {
          source = config.age.secrets."rclone.conf".path;
        };

        "agenix/ryan4yin-gpg-subkeys.priv.age" = {
          source = config.age.secrets."ryan4yin-gpg-subkeys.priv.age".path;
          mode = "0000";
        };

        # The following secrets are used by home-manager modules
        # So we need to make then readable by the user
        "agenix/alias-for-work.nushell" = {
          source = config.age.secrets."alias-for-work.nushell".path;
          mode = "0644"; # both the original file and the symlink should be readable and executable by the user
        };
      };
    }
  ]);
}
