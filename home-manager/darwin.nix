{ ... }:

{
  home.stateVersion = "24.11";

  home.sessionVariables = {
    EDITOR = "vim";
  };

  programs.home-manager.enable = true;

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  imports = [
    ./include/cli-darwin.nix
    ./include/shells.nix
    ./include/programming/nix.nix
    ./include/services/gpg.nix
    ./include/services/gpg-darwin.nix
    ./include/services/backup-darwin.nix
  ];
}
