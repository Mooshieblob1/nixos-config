{
  description = "NixOS configuration for host 'nixos' (user blob)";

  inputs = {
    # Pinned to the exact nixpkgs revision the system was already running on
    # the nixos-26.05 channel, so converting to a flake does not pull in a
    # channel jump. Bump this rev deliberately when you want to update.
    nixpkgs.url = "github:NixOS/nixpkgs/e8210c649915deed7080033cdbabcc19e40bb899";

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home-manager, tracking the matching 26.05 release branch and pinned to
    # the same nixpkgs as the system so HM and the OS never disagree on a
    # package set. Update with `nix flake update home-manager`.
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, lanzaboote, home-manager, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        lanzaboote.nixosModules.lanzaboote

        # home-manager as a NixOS module: `nixos-rebuild switch` builds the
        # system and blob's home generation together. useGlobalPkgs makes HM
        # use the system nixpkgs (and its allowUnfree); useUserPackages installs
        # user packages into /etc/profiles so they're visible system-wide.
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.blob = import ./home.nix;
        }
      ];
    };
  };
}
