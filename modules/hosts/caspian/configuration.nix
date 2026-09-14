{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.caspianConfiguration = {
    pkgs,
    lib,
    ...
  }: {
    imports = [
      self.nixosModules.caspianHardware
      self.nixosModules.base
      self.nixosModules.devices
      self.nixosModules.desktop

      self.nixosModules.gpt-dictate
      # self.nixosModules."plymouth-logorhythms"

      inputs.sops-nix.nixosModules.sops

      self.nixosModules.games
      self.nixosModules.gamedev
      self.nixosModules.networking
      self.nixosModules.prusaslicer3
      self.nixosModules.starcitizen
      self.nixosModules."programs-3d"
      self.nixosModules.sunshine
      self.nixosModules.wooting
    ];


    services.samba = {
      enable = true;
      openFirewall = true;

      # WSDD handles discovery for modern Windows clients.  These legacy/domain
      # daemons only lengthen the boot path for this guest-only share.
      nmbd.enable = false;
      winbindd.enable = false;

      settings.prism = {
        path = "/home/dazza/.local/share/PrismLauncher/instances";
        "read only" = "no";
        "guest ok" = "yes";
      };
    };

    services.samba-wsdd = {
      enable = true;
      openFirewall = true;
    };
    networking.hostName = "caspian";

    # BIOS GRUB belongs on the disk containing the Linux root filesystem.
    # /dev/nvme0n1 is the separate GPT Windows disk and has no BIOS Boot partition.
    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/nvme1n1";
    boot.loader.grub.useOSProber = true;
    boot.loader.timeout = 1;
    boot.loader.grub.gfxmodeBios = "1920x1080,auto";
    boot.loader.grub.gfxpayloadBios = "keep";
    boot.kernelPackages = pkgs.linuxPackages_latest;
    boot.supportedFilesystems = ["nfs" "ntfs"];

    # build aarch64 (rpi5) closures via qemu emulation
    boot.binfmt.emulatedSystems = ["aarch64-linux"];
    boot.binfmt.preferStaticEmulators = true;
    # graphics
    boot.kernelParams = ["nvidia_drm.fbdev=1"];
    services.xserver.videoDrivers = [
      "nvidia"
    ];
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
    };
    hardware.nvidia.open = false;

    # mount drive
    fileSystems."/mnt/samsung990pro" = {
      device = "/dev/disk/by-uuid/CC702C2D702C20A6";
      fsType = "ntfs-3g";
      options = ["rw" "uid=1000" "nofail" "noauto" "x-systemd.automount"];
    };

    # mount nas
    # fileSystems."/mnt/nas" = {
    #   device = "192.168.100.21:/mnt/nas-data/files-dazza";
    #   fsType = "nfs";
    #   options = ["x-systemd.automount" "noauto"];
    # };
    #
    # fileSystems."/mnt/nas-raw" = {
    #   device = "192.168.100.21:/mnt/";
    #   fsType = "nfs";
    #   options = ["x-systemd.automount" "noauto"];
    # };

    networking.networkmanager.enable = true;
    # This machine has Ethernet only; do not start an unused supplicant.
    networking.wireless.enable = lib.mkForce false;
    # Let Ethernet negotiation and DHCP finish asynchronously.  Nothing needed
    # for reaching the desktop requires the network to be fully configured.
    systemd.services.NetworkManager-wait-online.enable = false;

    # Type=idle adds an intentional ~5 second delay before the greeter process.
    systemd.services.greetd.serviceConfig.Type = lib.mkForce "simple";
    security.polkit.enable = true;
    networking.firewall.allowedTCPPorts = [3773];

    programs.gpt-dictate.enable = true;


    environment.sessionVariables.NIXOS_OZONE_WL = "1";


    users.users.dazza = {
      uid = 1000;
      isNormalUser = true;
      description = "Daren Drahos";
      extraGroups = ["networkmanager" "wheel" "storage" "dialout" "input"];
      packages = with pkgs; [
      ];
    };

    environment.systemPackages = with pkgs; [
      google-chrome
      kdePackages.dolphin
      kdePackages.kio # needed since 25.11
      kdePackages.kio-fuse #to mount remote filesystems via FUSE
      kdePackages.kio-extras #extra protocols support (sftp, fish and more)
      rsync
      rclone
      age
      sops
    ];

    system.autoUpgrade = {
      enable = true;
      flake = "/path/to/flake";
      flags = [
        "--print-build-logs"
      ];
      dates = "02:00";
      randomizedDelaySec = "45min";
    };


    system.stateVersion = "25.05";
  };
}
