{ config, pkgs, ... }:

{
  # ── Replace these with your own values ─────────────────────────────
  home.username = builtins.getEnv "USER";
  home.homeDirectory = "/Users/${config.home.username}";
  home.stateVersion = "24.11";

  home.packages = [
    # Add your host-specific packages here:
    # pkgs.google-cloud-sdk
    # pkgs.rclone
    # pkgs.restic
  ];

  home.file = { };

  programs.home-manager.enable = true;
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.bash.shellAliases = {
    vim = "nvim";
  };

  programs.zsh.shellAliases = {
    vim = "nvim";
  };

  # Override backup defaults if needed:
  # services.backup-home.repo = "rclone:gdrive:backups/my-mac";
  # services.backup-home.passwordCommand = "pass show restic/backup";

  # ── mcmonad tiling window manager ──────────────────────────────────
  # Uncomment to enable. Edit configFile to customise keybindings.
  # services.mcmonad = {
  #   enable = true;
  #   configFile = ''
  #     import MCMonad
  #     main = mcmonad defaultConfig
  #   '';
  # };
}
