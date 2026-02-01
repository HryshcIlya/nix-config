{
  nuenv,
  llm-agents,
  firefox-addons,
  nur,
  ...
}@args:
{
  nixpkgs.overlays = [
    nuenv.overlays.default
    llm-agents.overlays.default
    firefox-addons.overlays.default
    nur.overlays.default
  ]
  ++ (import ../../overlays args);
}
