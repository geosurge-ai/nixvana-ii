{
  description = "Home-Manager macOS configuration — generic, adaptable template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      ...
    }:

    let
      #──────────── helper: pkgs with overlays for a given system ────────────
      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          # Add your overlays here:
          # overlays = [ some-overlay.overlay ];
        };

      pkgsDarwin = mkPkgs "aarch64-darwin";

      #──────────── helper: construct one HM config ──────────────────────────
      mkHM =
        {
          hostname,
          modules,
          pkgs,
        }:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit hostname;
            myShell = pkgs.zsh;
          };
          inherit modules;
        };
    in
    {
      homeConfigurations = {
        # ── Example macOS host ──────────────────────────────────────────
        # Replace "my-mac" with your hostname.
        # Apply with: home-manager switch --flake .#my-mac
        my-mac = mkHM {
          hostname = "my-mac";
          pkgs = pkgsDarwin;
          modules = [
            ./darwin.nix
            ./example-host.nix
          ];
        };
      };
    };
}
