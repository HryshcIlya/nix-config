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
        "alias-for-work.nushell" = {
          file = "${mysecrets}/alias-for-work.nushell.age";
        }
        // user_readable;
      };

      # place secrets in /etc/
      environment.etc = {
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
