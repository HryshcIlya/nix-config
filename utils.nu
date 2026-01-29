def repeat-str [s: string, n: int] {
  (1..$n | each { $s } | str join)
}

# ================= NixOS related =========================

export def nixos-switch [
    name: string
    mode: string
] {
    print $"nixos-switch '($name)' in '($mode)' mode..."
    print (repeat-str "=" 50)
    if "debug" == $mode {
        # show details via nix-output-monitor
        nom build $".#nixosConfigurations.($name).config.system.build.toplevel" --show-trace --verbose
        nixos-rebuild switch --sudo --flake $".#($name)" --show-trace --verbose
    } else {
        nixos-rebuild switch --sudo --flake $".#($name)"
    }
}


# ====================== Misc =============================

export def make-editable [
    path: string
] {
    print (repeat-str "=" 50)
    let tmpdir = (mktemp -d)
    rsync -avz --copy-links $"($path)/" $tmpdir
    rsync -avz --copy-links --chmod=D2755,F744 $"($tmpdir)/" $path
}
