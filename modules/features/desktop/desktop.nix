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
      inputs.noctalia.nixosModules.default
    ];

    systemd.user.services.niri.enableDefaultPath = false;


    programs.noctalia = {
      enable = true;
      # Enables NetworkManager, Bluetooth, UPower, and a power profile service.
      recommendedServices.enable = true;
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
        # self'.packages.myNoctalia
        pkgs.xwayland-satellite
        pkgs.playerctl
        pkgs.kitty
      ];
      settings = {
        # bare minimum so noctalia is reachable at startup
        # spawn-at-startup = [(lib.getExe self'.packages.myNoctalia)];
        # spawn-at-startup = [(lib.getExe pkgs.noctalia)];
        spawn-at-startup = [
          (lib.getExe inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default)
        ];
        extraConfig = ''
          include optional=true "/home/dazza/.config/niri/config.kdl"
        '';
      };
    };
  };
}
