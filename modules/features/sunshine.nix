{ self, inputs, ... }: {
  flake.nixosModules.sunshine = { pkgs, lib, username, ... }: {
    # services.sunshine = {
    #   enable = true;
    #   autoStart = true;
    #   capSysAdmin = true; #wayland 
    #   openFirewall = true;
    # };
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
      package = pkgs.sunshine.override {
        cudaSupport = true;
        cudaPackages = pkgs.cudaPackages;
      };
    };
    users.users.${username} = {
      extraGroups = [ "uinput" "video" "render" ];
      packages = with pkgs; [
        moonlight-qt
      ];
    };

    hardware.uinput.enable = true;
  };
}
