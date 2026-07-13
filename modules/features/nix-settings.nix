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
    nix.settings.auto-optimise-store = true;
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    nix.settings.trusted-users = ["root" "${username}"];
    nixpkgs.config.allowUnfree = true;

    programs.nix-ld.enable = true;

    nix.settings.experimental-features = ["nix-command" "flakes"];
  };
}
