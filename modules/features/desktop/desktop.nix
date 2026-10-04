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
  }: let
    # PAM loads the system's modules into Noctalia's process at unlock time.
    # Build with system nixpkgs so libc, PAM, and Mesa stay compatible.
    noctalia = pkgs.callPackage "${inputs.noctalia}/nix/package.nix" {
      rev = inputs.noctalia.shortRev or "unknown";
    };
  in {
    packages.myNoctalia = pkgs.symlinkJoin {
      name = "noctalia-compatible";
      paths = [noctalia];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram "$out/bin/noctalia" \
          --set __EGL_VENDOR_LIBRARY_DIRS "${pkgs.mesa}/share/glvnd/egl_vendor.d"
      '';
      meta.mainProgram = "noctalia";
    };
    packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs; # THIS PART IS VERY IMPORTAINT, I FORGOT IT IN THE VIDEO!!!
      runtimePkgs = [
        self'.packages.myNoctalia
        pkgs.xwayland-satellite
        pkgs.playerctl
        pkgs.kitty
      ];
      settings = {
        # bare minimum so noctalia is reachable at startup
        spawn-at-startup = [(lib.getExe self'.packages.myNoctalia)];
        extraConfig = ''
          include optional=true "/home/dazza/.config/niri/config.kdl"
        '';
      };
    };
  };
}
