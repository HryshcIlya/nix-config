{ pkgs, ... }:
{
  home.packages = [ pkgs.nur.repos.Ev357.helium ];

  # Widevine DRM support for streaming services (Netflix, Spotify, etc.)
  home.file.".config/net.imput.helium/WidevineCdm/latest-component-updated-widevine-cdm".text =
    builtins.toJSON
      { Path = "${pkgs.widevine-cdm}/share/google/chrome/WidevineCdm"; };
}
