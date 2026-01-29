{ nuenv, llm-agents, ... }@args:
{
  nixpkgs.overlays = [
    nuenv.overlays.default
    llm-agents.overlays.default
  ]
  ++ (import ../../overlays args);
}
