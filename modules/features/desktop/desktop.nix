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

    programs.noctalia = {
      enable = true;
      # Enables NetworkManager, Bluetooth, UPower, and a power profile service.
      recommendedServices.enable = false;
    };
  };
  perSystem = {
    pkgs,
    lib,
    ...
  }: {
    packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs; # THIS PART IS VERY IMPORTAINT, I FORGOT IT IN THE VIDEO!!!
      runtimePkgs = [
        pkgs.noctalia
        pkgs.xwayland-satellite
        pkgs.playerctl
        pkgs.kitty
      ];
      settings = {
        # bare minimum so noctalia is reachable at startup
        spawn-at-startup = [(lib.getExe pkgs.noctalia)];
        extraConfig = ''
          include optional=true "/home/dazza/.config/niri/config.kdl"
        '';
      };
    };
  };
}
