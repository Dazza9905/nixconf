{self, ...}: {
  flake.nixosModules.touchControls = {pkgs, username, ...}: let
    controls = self.packages.${pkgs.stdenv.hostPlatform.system}.touch-controls;
    keyboard = self.packages.${pkgs.stdenv.hostPlatform.system}.touch-keyboard;
  in {
    environment.systemPackages = [controls];
    boot.kernelModules = ["uinput"];
    # Input injection only; do not grant access to read physical keyboards.
    services.udev.extraRules = ''
      SUBSYSTEM=="misc", KERNEL=="uinput", OWNER="${username}", MODE="0600", OPTIONS+="static_node=uinput"
    '';

    systemd.user.services.touch-keyboard = {
      description = "Movable touch keyboard";
      partOf = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        ExecStart = "${keyboard}/bin/wvkbd-tablet --non-exclusive --margin 20 --width-ratio 65 --border 2 --padding 24 --corner 16 -H 320 -L 320 --no-popup";
        Restart = "on-failure";
      };
    };

    systemd.user.services.touch-controls-bar = {
      description = "Add permanent touch controls to the Noctalia bar";
      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${controls}/bin/touch-controls install-bar";
      };
    };
  };

  perSystem = {pkgs, lib, self', ...}: {
    packages.touch-keyboard = pkgs.wvkbd.overrideAttrs (old: {
      pname = "touch-keyboard";
      version = "0.20-tablet-a3cf72d";
      src = pkgs.fetchFromGitHub {
        owner = "mcinnisdev";
        repo = "wvkbd";
        rev = "a3cf72d6d861557be930cb116b7293eb7aaa6c5c";
        hash = "sha256-L+H4sa6FxQ15s/ruy62dmH+kcOkkYmGRvEHJ7iIN+Z0=";
      };
      patches = (old.patches or []) ++ [./touch/wvkbd-drag.patch];
      postPatch = (old.postPatch or "") + ''
        cp ${./touch/shortcuts.c} shortcuts.c
        cp ${./touch/shortcuts.h} shortcuts.h
      '';
      makeFlags = (old.makeFlags or []) ++ ["LAYOUT=tablet"];
      meta = old.meta // {mainProgram = "wvkbd-tablet";};
    });

    packages.touch-controls = let
      python = pkgs.python3.withPackages (ps: [ps.tomlkit]);
    in pkgs.writeShellApplication {
      name = "touch-controls";
      runtimeInputs = [pkgs.niri pkgs.noctalia pkgs.systemd pkgs.libnotify];
      text = ''
        export TOUCH_CONTROLS_COMMAND="$0"
        export TOUCH_KEYBOARD_EXEC="${lib.getExe self'.packages.touch-keyboard}"
        exec ${lib.getExe python} ${./touch/controls.py} "$@"
      '';
    };
  };
}
