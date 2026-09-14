{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.prusaslicer3 = {pkgs, ...}: {
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
      overrides."com.prusa3d.PrusaSlicer".Environment = {
        GDK_SCALE = "2";
        GDK_DPI_SCALE = "0.75";
      };
    };

    environment.systemPackages = [
      (pkgs.makeDesktopItem {
        name = "com.prusa3d.PrusaSlicer";
        desktopName = "Prusa Slicer 3.0";
        comment = "Slice 3D models for printing with PrusaSlicer 3.0";
        exec = "${pkgs.flatpak}/bin/flatpak run com.prusa3d.PrusaSlicer %F";
        icon = "com.prusa3d.PrusaSlicer";
        terminal = false;
        categories = ["Graphics" "3DGraphics" "Engineering"];
        mimeTypes = [
          "model/3mf"
          "model/stl"
          "application/vnd.ms-3mfdocument"
        ];
      })
    ];
  };
}
