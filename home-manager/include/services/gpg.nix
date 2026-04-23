{ pkgs, ... }:

{
  # On Darwin, the entire GPG toolchain (packages, pinentry, agent) is
  # managed by gpg-darwin.nix. This module only activates on Linux.
  services.gpg-agent = {
    enable = !pkgs.stdenv.isDarwin;
    pinentry.package = pkgs.pinentry-curses;
  };
}
