{ pkgs, ... }:

{
  home.packages = [
    pkgs.tmux
    pkgs.git
    pkgs.gdu

    pkgs.mc

    pkgs.parallel
    pkgs.expect

    pkgs.jq
    pkgs.curl

    pkgs.fzf
    pkgs.fzf-obc
    pkgs.sysz
    pkgs.tmuxPlugins.tmux-fzf

    # GPG toolchain is declared in gpg-darwin.nix (single source of truth)

    pkgs.util-linux
    pkgs.watch

    pkgs.mosh

    pkgs.asciinema
  ];
}
