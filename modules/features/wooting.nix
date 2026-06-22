{ self, inputs, ... }: {
  flake.nixosModules.wooting = { pkgs, lib, username, ... }: {
    services.udev.packages = [
      (pkgs.writeTextFile {
        name = "wooting-udev-rules";
        destination = "/lib/udev/rules.d/70-wooting.rules";
        text = ''
          # Wooting One Legacy
          SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="ff01", TAG+="uaccess"
          SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="ff01", TAG+="uaccess"

          # Wooting One Update Mode
          SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", TAG+="uaccess"

          # Wooting Two Legacy
          SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="ff02", TAG+="uaccess"
          SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="ff02", TAG+="uaccess"

          # Wooting Two Update Mode
          SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2461", TAG+="uaccess"

          # Generic Wooting Devices
          SUBSYSTEM=="hidraw", ATTRS{idVendor}=="31e3", TAG+="uaccess"
          SUBSYSTEM=="usb", ATTRS{idVendor}=="31e3", TAG+="uaccess"
        '';
      })
    ];


    users.users.${username} = {
      packages = with pkgs; [
        wootility
      ];
    };

  };
}
