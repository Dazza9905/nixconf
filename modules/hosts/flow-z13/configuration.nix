{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.flowz13Configuration = {
    pkgs,
    lib,
    ...
  }: {
    imports = [
      self.nixosModules.flowz13Hardware
      self.nixosModules.nix-settings
      self.nixosModules.time-lang
      self.nixosModules.devices
      self.nixosModules.desktop

      self.nixosModules.networking
      self.nixosModules."programs-3d"
    ];

    networking.hostName = "flow-z13";

    # bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # graphics
    boot.kernelParams = ["nvidia_drm.fbdev=1"];
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
    };
    hardware.nvidia = {
      open = false;
      prime = {
        offload.enable = true;
        offload.enableOffloadCmd = true;
        intelBusId = "PCI:0@0:2:0";
        nvidiaBusId = "PCI:1@0:0:0";
      };
    };
    services.xserver.videoDrivers = [
      "modesetting"
      "nvidia"
    ];

    # battery and asus stuff
    services.upower.enable = true;
    services.asusd.enable = true;
    services.supergfxd.enable = true;

    networking.networkmanager.enable = true;

    users.users.dazza = {
      isNormalUser = true;
      description = "Daren Drahos";
      extraGroups = ["networkmanager" "wheel"];
      packages = with pkgs; [
      ];
    };

    environment.systemPackages = with pkgs; [
    ];

    system.stateVersion = "25.05"; # Did you read the comment?
  };
}
