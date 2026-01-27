{
  nu_scripts,
  ...
}:
{
  programs.nushell = {
    # load the alias file for work
    # the file must exist, otherwise nushell will complain about it!
    #
    # currently, nushell does not support conditional sourcing of files
    # https://github.com/nushell/nushell/issues/8214
    extraConfig = ''
      source /etc/agenix/alias-for-work.nushell

      $env.CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"

      # Directories in this constant are searched by the
      # `use` and `source` commands.
      const NU_LIB_DIRS = $NU_LIB_DIRS ++ ['${nu_scripts}']

      # -*- completion -*-
      use custom-completions/cargo/cargo-completions.nu *
      use custom-completions/curl/curl-completions.nu *
      use custom-completions/git/git-completions.nu *
      use custom-completions/glow/glow-completions.nu *
      use custom-completions/just/just-completions.nu *
      use custom-completions/make/make-completions.nu *
      use custom-completions/man/man-completions.nu *
      use custom-completions/nix/nix-completions.nu *
      use custom-completions/ssh/ssh-completions.nu *
      use custom-completions/tar/tar-completions.nu *
      use custom-completions/tcpdump/tcpdump-completions.nu *
      use custom-completions/zellij/zellij-completions.nu *
      use custom-completions/zoxide/zoxide-completions.nu *

      # -*- alias -*-
      use aliases/git/git-aliases.nu *
      use aliases/eza/eza-aliases.nu *
      use aliases/bat/bat-aliases.nu *

      # a wrapper around the jc cli tool, convert cli outputs to nushell tables
      # use modules/jc
    '';
  };
}
