{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

    zen-browser = {
          url = "github:youwen5/zen-browser-flake";
          inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-citizen.url = "github:LovingMelody/nix-citizen";

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  # Optional - updates underlying without waiting for nix-citizen to update
    nix-gaming.url = "github:fufexan/nix-gaming";
    nix-citizen.inputs.nix-gaming.follows = "nix-gaming";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./modules);
}
