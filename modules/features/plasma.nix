{ self, inputs, ... }: {
  flake.nixosModules.plasma = { config, pkgs, ... }: {
    services.xserver.enable = true;

    services.displayManager.sddm.enable = true;
    services.desktopManager.plasma6.enable = true;

    services.xserver.xkb = {
     layout = "us";
     variant = "";
    };

  };

perSystem = { pkgs, ... }: {
    packages.myPlasma = pkgs.plasma5Packages.plasma-workspace; # dummy, just to export per-system
  };
  
}


