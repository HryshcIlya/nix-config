# Refer:
# - Flatpak manifest's docs:
#   - https://docs.flatpak.org/en/latest/manifests.html
#   - https://docs.flatpak.org/en/latest/sandbox-permissions.html
# - LibreWolf's flatpak manifest: https://github.com/flathub/io.gitlab.librewolf-community/blob/master/io.gitlab.librewolf-community.json
{
  lib,
  librewolf,
  mkNixPak,
  buildEnv,
  makeDesktopItem,
  ...
}:

let
  appId = "io.gitlab.librewolf-community";
  wrapped = mkNixPak {
    config =
      {
        config,
        sloth,
        ...
      }:
      {
        app = {
          package = librewolf;
          binPath = "bin/librewolf";
        };
        flatpak.appId = appId;

        imports = [
          ./modules/gui-base.nix
          ./modules/network.nix
          ./modules/common.nix
        ];

        bubblewrap = {
          # To trace all the home files LibreWolf accesses, you can use the following nushell command:
          #   just trace-access librewolf
          # See the Justfile in the root of this repository for more information.
          bind.rw = [
            # given the read write permission to the following directories.
            # NOTE: sloth.mkdir is used to create the directory if it does not exist!
            (sloth.mkdir (sloth.concat' sloth.homeDir "/.librewolf"))

            sloth.xdgDocumentsDir
            sloth.xdgDownloadDir
            sloth.xdgMusicDir
            sloth.xdgVideosDir
            sloth.xdgPicturesDir
          ];
          bind.ro = [
            "/sys/bus/pci"
            [
              "${config.app.package}/lib/librewolf"
              "/app/etc/librewolf"
            ]

            # Unsure
            (sloth.concat' sloth.xdgConfigHome "/dconf")
          ];

          sockets = {
            x11 = false;
            wayland = true;
            pipewire = true;
          };
        };
      };
  };
  exePath = lib.getExe wrapped.config.script;
in
buildEnv {
  inherit (wrapped.config.script) name meta passthru;
  paths = [
    wrapped.config.script
    (makeDesktopItem {
      name = appId;
      desktopName = "LibreWolf";
      genericName = "LibreWolf Boxed";
      comment = "LibreWolf Browser";
      exec = "${exePath} %U";
      terminal = false;
      icon = "librewolf";
      startupNotify = true;
      startupWMClass = "librewolf";
      type = "Application";
      categories = [
        "Network"
        "WebBrowser"
      ];
      mimeTypes = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "application/vnd.mozilla.xul+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];

      actions = {
        new-private-window = {
          name = "New Private Window";
          exec = "${exePath} --private-window %U";
        };
        new-window = {
          name = "New Window";
          exec = "${exePath} --new-window %U";
        };
        profile-manager-window = {
          name = "Profile Manager";
          exec = "${exePath} --ProfileManager";
        };
      };

      extraConfig = {
        X-Flatpak = appId;
      };
    })
  ];
}
