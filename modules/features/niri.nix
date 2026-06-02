{ self, inputs, ... }: {
flake.nixosModules.niri = { pkgs, lib, ... }: {
  programs.niri = {
    enable = true;
    package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "niri-session --config /home/dazza/.config/niri/config.kdl";
        user = "dazza";
      };
    };
  };
  systemd.user.services.niri.enableDefaultPath = false;
};
perSystem = { pkgs, lib, self', ... }: {
  packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
    inherit pkgs; # THIS PART IS VERY IMPORTAINT, I FORGOT IT IN THE VIDEO!!!
    extraPackages = [
      self'.packages.myNoctalia
      pkgs.xwayland-satellite
      pkgs.playerctl
      pkgs.kitty
    ];
    settings = {
      # bare minimum so noctalia is reachable at startup
      spawn-at-startup = [ (lib.getExe self'.packages.myNoctalia) ];
      extraConfig = ''
        include optional=true "/home/dazza/.config/niri/config.kdl"
      '';
    };
  };
};
}
