{
  nuenv,
  llm-agents,
  firefox-addons,
  ...
}@args:
{
  nixpkgs.overlays = [
    nuenv.overlays.default
    llm-agents.overlays.default
    firefox-addons.overlays.default
  ]
  ++ (import ../../overlays args);
}
