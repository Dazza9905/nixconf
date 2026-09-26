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
      recommendedServices.enable = false;
    };
  };
  perSystem = {
    pkgs,
    lib,
    self',
    ...
  }: let
    # Use the upstream package built by Noctalia's Cachix workflow.
    noctalia = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  in {
    packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs; # THIS PART IS VERY IMPORTAINT, I FORGOT IT IN THE VIDEO!!!
      runtimePkgs = [
        noctalia
        pkgs.xwayland-satellite
        pkgs.playerctl
        pkgs.kitty
      ];
      settings = {
        # bare minimum so noctalia is reachable at startup
        spawn-at-startup = [(lib.getExe noctalia)];
        extraConfig = ''
          include optional=true "/home/dazza/.config/niri/config.kdl"
        '';
      };
    };
  };
}
