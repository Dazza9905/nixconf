
{ self, inputs, ... }:
{
  flake.nixosModules.dazzapcConfiguration = { pkgs, lib, ... }: {

    imports = [
      self.nixosModules.dazzapcHardware
      self.nixosModules.niri
      # self.nixosModules.plasma
      self.nixosModules.zen
      self.nixosModules.fonts
      self.nixosModules.yazi
      self.nixosModules.networking
      self.nixosModules.starcitizen
      self.nixosModules."3d"
      self.nixosModules.games
      self.nixosModules.sunshine
      self.nixosModules.ncspot
      self.nixosModules.audiorelay
      self.nixosModules.wooting
    ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    
services.gnome.gnome-keyring.enable = true;
services.udisks2.enable = true;
# This allows your login password to unlock the keyring automatically
security.pam.services.greetd.enableGnomeKeyring = true; 
# (Replace 'greetd' with your display manager, e.g., 'sddm', 'gdm', or 'login' if using TTY)

# Ensure the DBus service is visible to Niri
systemd.user.services.gnome-keyring = {
  description = "GNOME Keyring";
  serviceConfig = {
    ExecStart = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --foreground --components=secrets";
    Restart = "on-abort";
  };
  wantedBy = [ "graphical-session.target" ];
};
    security.polkit.enable = true;
    # Bootloader.
    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/nvme0n1";
    boot.loader.grub.useOSProber = true;
    # Use latest kernel.
    boot.kernelPackages = pkgs.linuxPackages_latest;

    boot.supportedFilesystems = [ "nfs" "ntfs" ];

    fileSystems."/mnt/nas" = {
      device = "192.168.100.21:/mnt/nas-data/files-dazza";
      fsType = "nfs";
      options = [ "x-systemd.automount" "noauto" ];
    };



    networking.hostName = "dazzapc"; # Define your hostname.
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Enable networking
    networking.networkmanager.enable = true;

    # Set your time zone.
    time.timeZone = "Europe/Bratislava";

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "sk_SK.UTF-8";
      LC_IDENTIFICATION = "sk_SK.UTF-8";
      LC_MEASUREMENT = "sk_SK.UTF-8";
      LC_MONETARY = "sk_SK.UTF-8";
      LC_NAME = "sk_SK.UTF-8";
      LC_NUMERIC = "sk_SK.UTF-8";
      LC_PAPER = "sk_SK.UTF-8";
      LC_TELEPHONE = "sk_SK.UTF-8";
      LC_TIME = "sk_SK.UTF-8";
    };

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    hardware.nvidia = {
      modesetting.enable = true; # enables nvidia_drm.modeset=1
      powerManagement.enable = true; # save/restore GPU state on suspend/resume
    };

    hardware.nvidia.open = false;

    boot.kernelParams = [ "nvidia_drm.fbdev=1" ];


    fileSystems."/mnt/samsung990pro" = {
      device = "/dev/disk/by-uuid/CC702C2D702C20A6";
      fsType = "ntfs-3g"; 
      options = [ "rw" "uid=1000" "nofail" ];
    };



    services.xserver.videoDrivers = [
      "nvidia"
    ];

    services.flatpak.enable = true;
  systemd.services.flatpak-repo = {
    wantedBy = ["multi-user.target"];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };
  system.activationScripts.install-riff-flatpak = {
    text = ''
      ${pkgs.flatpak}/bin/flatpak install -y flathub dev.diegovsky.Riff
    '';
    deps = [];
  };


    #bluetooth
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = false;
    };

    #printing 
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    services.printing = {
      enable = true;
      drivers = with pkgs; [
        cups-filters
        cups-browsed
      ];
    };


    # Enable sound with pipewire.
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };

    programs.localsend = {
      enable = true;
    };
    # Enable touchpad support (enabled default in most desktopManager).
    # services.xserver.libinput.enable = true;

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.dazza = {
      uid = 1000;
      isNormalUser = true;
      description = "Daren Drahos";
      extraGroups = [ "networkmanager" "wheel" "storage" "dialout" ];
      packages = with pkgs; [
        github-cli
        kitty
        anki
        vesktop
        playerctl
        beeper
        localsend
        kdePackages.dolphin
        kdePackages.kio
        kdePackages.kio-fuse
        kdePackages.kio-extras
        gparted
        claude-code
      ];
    };


        # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
        btop
        pciutils
        lazygit
        neovim
        git
        stow
        fd
        fzf
        eza
        zip
        unzip
        bat
        nwg-displays
        pavucontrol
        ntfs3g
        dust
        zellij
        ripgrep
        bob-nvim
        gitui
        zoxide
        starship
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    ];

    nix.settings.auto-optimise-store = true;
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
    };
    programs.gamemode.enable = true;

    programs.fish.enable = true;
    users.extraUsers.dazza = {
      shell = pkgs.fish;
    }; 

    nixpkgs.config.allowUnfree = true;

    system.stateVersion = "25.05"; 
  };
}
