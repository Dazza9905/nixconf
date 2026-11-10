{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.desktop = {
    pkgs,
    lib,
    ...
  }: {
    programs.niri = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri;
    };

    imports = [
      inputs.noctalia-greeter.nixosModules.default
      self.nixosModules.enviroment
      self.nixosModules.greeter
      # Temporarily disabled while touch-keyboard support is in progress.
      # self.nixosModules.touchControls
    ];

    systemd.user.services.niri.enableDefaultPath = false;

    environment.systemPackages = [self.packages.${pkgs.stdenv.hostPlatform.system}.myWarpd];

    programs.noctalia = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNoctalia;
      # Enables NetworkManager, Bluetooth, UPower, and a power profile service.
      recommendedServices.enable = false;
    };
  };
  perSystem = {
    pkgs,
    lib,
    self',
    ...
  }: {
    packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs; # THIS PART IS VERY IMPORTAINT, I FORGOT IT IN THE VIDEO!!!
      runtimePkgs = [
        self'.packages.myNoctalia
        self'.packages.myWarpd
        pkgs.xwayland-satellite
        pkgs.playerctl
        pkgs.kitty
      ];
      settings = {
        # bare minimum so noctalia is reachable at startup
        spawn-at-startup = [(lib.getExe self'.packages.myNoctalia)];
        binds = {
          "Mod+Alt+G".spawn = [(lib.getExe self'.packages.myWarpd) "--grid"];
          "F15".spawn = [(lib.getExe self'.packages.myWarpd) "--normal"];
          "F16".spawn = [(lib.getExe self'.packages.myWarpd) "--hint"];
          # Default evdev XKB names for physical F15 and F16.
          "XF86Launch6".spawn = [(lib.getExe self'.packages.myWarpd) "--normal"];
          "XF86Launch7".spawn = [(lib.getExe self'.packages.myWarpd) "--hint"];
          "Mod+Alt+C".spawn = [(lib.getExe self'.packages.myWarpd) "--normal"];
        };
        extraConfig = ''
          include optional=true "/home/dazza/.config/niri/config.kdl"
          // Keep warpd above windows even if local rules place layers in the backdrop.
          layer-rule {
            match namespace="^warpd$"
            place-within-backdrop false
          }
        '';
      };
    };
  };
}
