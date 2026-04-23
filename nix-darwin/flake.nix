{
  description = "nix-darwin system flake — generic macOS system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
    }:
    let
      # ── Change this to your machine's hostname ──────────────────────
      hostName = "my-mac";

      configuration =
        { pkgs, ... }:
        {
          environment.systemPackages = [
            pkgs.htop
            pkgs.direnv
            pkgs.nix-direnv
            home-manager.packages.${pkgs.system}.home-manager
            pkgs.docker
            pkgs.docker-compose
          ];

          programs.direnv.enable = true;
          programs.direnv.nix-direnv.enable = true;

          nix.enable = false;
          nix.settings.experimental-features = "nix-command flakes";

          system.configurationRevision = self.rev or self.dirtyRev or null;
          system.stateVersion = 6;

          nixpkgs.hostPlatform = "aarch64-darwin";

          services.openssh.enable = true;

          # ── Replace with your username ──────────────────────────────
          users.users.youruser = {
            home = "/Users/youruser";
            # Optional: fetch SSH keys from GitHub
            # openssh.authorizedKeys.keyFiles = [
            #   (builtins.fetchurl {
            #     url = "https://github.com/yourusername.keys";
            #     sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
            #   })
            # ];
          };

          networking.hostName = hostName;
          networking.computerName = hostName;
          networking.localHostName = hostName;
        };
    in
    {
      # Build with: darwin-rebuild build --flake .#my-mac
      darwinConfigurations.${hostName} = nix-darwin.lib.darwinSystem {
        modules = [ configuration ];
      };
    };
}
