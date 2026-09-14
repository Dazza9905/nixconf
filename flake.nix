{
  nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
    import-tree = {
      url = "github:vic/import-tree";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    #bilt on top of wrappers
    wrapper-modules = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wrappers = {
      url = "github:Lassulus/wrappers";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-desktop-linux = {
      url = "github:ilysenko/codex-desktop-linux";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Optional - updates underlying without waiting for nix-citizen to update
    # nix-gaming = {
    #   url = "github:fufexan/nix-gaming";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # nix-citizen = {
    #   url = "github:LovingMelody/nix-citizen";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # nix-citizen.inputs.nix-gaming.follows = "nix-gaming";
    nix-citizen.url = "github:LovingMelody/nix-citizen";

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    whisper-dictation.url = "github:jacopone/whisper-dictation";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        (inputs.import-tree ./modules/features)
        (inputs.import-tree ./modules/fleet)
        ./modules/homelab/default.nix
        (inputs.import-tree ./modules/hosts)
        ./modules/parts.nix
      ];
    };
}
