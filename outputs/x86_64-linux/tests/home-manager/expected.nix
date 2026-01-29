{
  myvars,
  lib,
}:
let
  username = myvars.username;
  hosts = [
    "ai-niri"
  ];
in
lib.genAttrs hosts (_: "/home/${username}")
