{
  myvars,
  lib,
}:
let
  username = myvars.username;
  hosts = [
    "ai"
  ];
in
lib.genAttrs hosts (_: "/home/${username}")
