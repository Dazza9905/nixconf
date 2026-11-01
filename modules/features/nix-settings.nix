{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.nix-settings = {
    pkgs,
    lib,
    username,
    ...
  }: {
    # Enable the Noctalia cache even when flake nixConfig is not accepted.
    nix.settings.extra-substituters = ["https://noctalia.cachix.org"];
    nix.settings.extra-trusted-public-keys = ["noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="];

    nix.settings.auto-optimise-store = true;
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    nix.settings.trusted-users = ["root" "${username}"];
    nixpkgs.config.allowUnfree = true;

    programs.nix-ld.enable = true;

    nix.settings.experimental-features = ["nix-command" "flakes"];

    # Keep CLI package completion and language servers on our locked nixpkgs.
    nix.registry.nixpkgs.flake = inputs.nixpkgs;
    nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];
  };
}
