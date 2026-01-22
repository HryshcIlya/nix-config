{
  pkgs,
  ...
}:
###########################################################
#
# Alacritty Configuration
#
# Useful Hot Keys:
#   1. Increase Font Size: `ctrl + shift + =` | `ctrl + shift + +`
#   2. Decrease Font Size: `ctrl + shift + -` | `ctrl + shift + _`
#   3. Search Text: `ctrl + shift + N`
#   4. And Other common shortcuts such as Copy, Paste, Cursor Move, etc.
#
# Note: Alacritty do not have support for Tabs, and any graphic protocol.
#
###########################################################
{
  programs.alacritty = {
    enable = true;
    # https://alacritty.org/config-alacritty.html
    settings = {
      window = {
        opacity = 0.93;
        startup_mode = "Maximized"; # Maximized window
        dynamic_title = true;
        decorations = "None"; # Show neither borders nor title bar
      };
      scrolling = {
        history = 10000;
      };
      font = {
        bold = {
          family = "Maple Mono NF CN";
        };
        italic = {
          family = "Maple Mono NF CN";
        };
        normal = {
          family = "Maple Mono NF CN";
        };
        bold_italic = {
          family = "Maple Mono NF CN";
        };
        size = 13;
      };
      terminal = {
        # Spawn a nushell in login mode via `bash`
        shell = {
          program = "${pkgs.bash}/bin/bash";
          args = [
            "--login"
            "-c"
            "nu --login --interactive"
          ];
        };
        # Controls the ability to write to the system clipboard with the OSC 52 escape sequence.
        # It's used by zellij to copy text to the system clipboard.
        osc52 = "CopyPaste";
      };
    };
  };
}
