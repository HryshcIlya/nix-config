{
  pkgs,
  zen-browser,
  ...
}:
let
  addons = pkgs.firefox-addons;
in
{
  imports = [
    zen-browser.homeModules.twilight
  ];

  programs.zen-browser = {
    enable = true;

    profiles.default = {
      isDefault = true;

      extensions.packages = with addons; [
        proton-pass
        sponsorblock
        yomitan
        asbplayer
        youtube-recommended-videos
        # AdGuard is not in NUR, using fetchFirefoxAddon
        (pkgs.fetchFirefoxAddon {
          name = "adguard-adblocker";
          url = "https://addons.mozilla.org/firefox/downloads/latest/adguard-adblocker/latest.xpi";
          hash = "sha256-EZx9iJcS0vUTbZmbf38Zdmwzg2Ndijx8ijFRfn4AduQ=";
        })
      ];
    };
  };
}
