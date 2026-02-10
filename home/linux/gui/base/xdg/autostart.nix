{ pkgs, lib, ... }:
{
  # XDG autostart entries - ensures apps start after portal services are ready
  xdg.autostart.enable = true;
  # This fixes nixpak sandboxed apps (like librewolf) accessing mapped folders correctly
  xdg.autostart.entries = [
    "${pkgs.foot}/share/applications/foot.desktop"
    "${pkgs.alacritty}/share/applications/Alacritty.desktop"
    "${pkgs.ghostty}/share/applications/com.mitchellh.ghostty.desktop"

    # nixpaks
    "${pkgs.nixpaks.librewolf}/share/applications/io.gitlab.librewolf-community.desktop"
    "${pkgs.nixpaks.telegram-desktop}/share/applications/org.telegram.desktop.desktop"
  ]
  ++ [
    "${pkgs.nur.repos.Ev357.helium}/share/applications/helium.desktop"
  ];
}
