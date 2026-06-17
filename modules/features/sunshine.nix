{ self, inputs, ... }: {
  flake.nixosModules.sunshine = { pkgs, lib, username, ... }: {
    # services.sunshine = {
    #   enable = true;
    #   autoStart = true;
    #   capSysAdmin = true; #wayland 
    #   openFirewall = true;
    # };
    #
    # users.users.${username} = {
    #   extraGroups = [ "uinput" ];
    # };
    # hardware.uinput.enable = true;
  };
}
