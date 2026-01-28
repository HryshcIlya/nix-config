{ config, ... }:
let
  mkSymlink = config.lib.file.mkOutOfStoreSymlink;
in
{
  programs.ssh.matchBlocks."github.com".identityFile = "${config.home.homeDirectory}/.ssh/idols-ai";

  xdg.configFile."niri/niri-hardware.kdl".source =
    mkSymlink "${config.home.homeDirectory}/nix-config/hosts/idols-ai/niri-hardware.kdl";
}
