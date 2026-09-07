{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.prusaslicer3 = {
    imports = [inputs.nix-flatpak.nixosModules.nix-flatpak];

    services.flatpak = {
      enable = true;
      remotes = [
        {
          name = "flathub";
          location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
        }
        {
          name = "flathub-beta";
          location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
        }
      ];
      packages = [
        {
          appId = "com.prusa3d.PrusaSlicer";
          origin = "flathub-beta";
        }
      ];
    };
  };
}
