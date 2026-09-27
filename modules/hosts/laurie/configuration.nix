{
  self,
  inputs,
  ...
}: {
  flake.nixosModules."laurieConfiguration" = {
    pkgs,
    lib,
    ...
  }: {
    imports = [
      self.nixosModules."laurieHardware"
      self.nixosModules.base
      self.nixosModules.devices
      self.nixosModules.desktop
      self.nixosModules.printing
      self.nixosModules.gpt-dictate
      self.nixosModules.wooting
      
      self.nixosModules.games
      self.nixosModules.networking
      self.nixosModules."programs-3d"
    ];

    networking.hostName = "laurie";

    # bootloader
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.timeout = 1;
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # faster initrd: systemd stage-1 + zstd compression
    boot.initrd.systemd.enable = true;
    boot.initrd.compressor = "zstd";

    # skip waiting for a full network connection before declaring boot done
    systemd.services.NetworkManager-wait-online.enable = false;

    # graphics + Intel iGPU power saving
    boot.kernelParams = [
      "nvidia_drm.fbdev=1"
      "nvidia_drm.modeset=1"
      "i915.enable_psr=1" # panel self-refresh
      "i915.enable_fbc=1" # framebuffer compression
      "mem_sleep_default=deep" # S3 deep sleep on suspend
    ];
    # preserve GPU memory across suspend so nvidia-modeset can resume cleanly
    boot.extraModprobeConfig = ''
      options nvidia NVreg_PreserveVideoMemoryAllocations=1
      options nvidia NVreg_TemporaryFilePath=/var/tmp
      options nvidia NVreg_DynamicPowerManagementVideoMemoryThreshold=0
    '';
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = true;
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

    networking = {
      networkmanager = {
        enable = true;
        # Keep DHCP DNS out of resolved: dnsproxy handles FIIT explicitly.
        dns = lib.mkForce "none";
        settings.main.systemd-resolved = false;
      };
      # Pangolin ignores 127.0.0.0/8 when discovering upstream resolvers.
      # This address stays on lo; it is not a DNS server exposed on Wi-Fi.
      interfaces.lo.ipv4.addresses = [{ address = "192.0.2.53"; prefixLength = 32; }];
      nameservers = [ "192.0.2.53" ];
    };

    services.resolved = {
      enable = true;
      settings.Resolve = {
        # Encryption is handled by dnsproxy. Pangolin installs its own ~.
        # route when connected; without it, resolved uses the proxy below.
        DNSOverTLS = "false";
        FallbackDNS = [];
      };
    };

    services.dnsproxy = {
      enable = true;
      settings = {
        listen-addrs = [ "192.0.2.53" ];
        listen-ports = [ 53 ];
        cache = true;
        # IP endpoints avoid bootstrapping DoH through filtered plain DNS.
        upstream = [
          "https://1.1.1.1/dns-query"
          "https://1.0.0.1/dns-query"
          "[/fiit.stuba.sk/]147.175.159.11"
          "[/fiit.stuba.sk/]147.175.111.15"
        ];
      };
    };
    systemd.services.dnsproxy = {
      requires = [ "network-addresses-lo.service" ];
      after = [ "network-addresses-lo.service" ];
    };

    # battery and asus stuff
    services.upower.enable = true;
    services.asusd.enable = true;
    # supergfxd persists the GPU mode across reboots in /etc/asusd/supergfxd.conf
    # do NOT set a default mode here so manual changes (Integrated/Hybrid/etc.) survive rebuilds
    services.supergfxd.enable = true;

    # suspend on lid close (logind defaults to ignore on Wayland without a DE)
    services.logind = {
      lidSwitch = "suspend";
      lidSwitchExternalPower = "suspend";
    };

    # dynamic CPU frequency + turbo boost based on load and AC/battery state
    services.auto-cpufreq.enable = true;
    services.auto-cpufreq.settings = {
      battery = {
        governor = "powersave";
        turbo = "auto";
      };
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };

    # mount nas
    fileSystems."/mnt/nas" = {
      device = "192.168.100.21:/mnt/nas-data/files-dazza";
      fsType = "nfs";
      options = ["x-systemd.automount" "noauto"];
    };

    # fileSystems."/mnt/nas-raw" = {
    #   device = "192.168.100.21:/mnt/";
    #   fsType = "nfs";
    #   options = ["x-systemd.automount" "noauto"];
    # };

    # SD card reader disabled — unused; caused sdhci errors on resume
    # re-enable by uncommenting below and removing the blacklist
    boot.blacklistedKernelModules = ["sdhci_pci"];
    # systemd.services.sdhci-resume = {
    #   description = "Reload sdhci_pci after resume";
    #   after = ["suspend.target" "hibernate.target" "hybrid-sleep.target"];
    #   wantedBy = ["suspend.target" "hibernate.target" "hybrid-sleep.target"];
    #   serviceConfig = {
    #     Type = "oneshot";
    #     ExecStart = "/bin/sh -c 'modprobe -r sdhci_pci && modprobe sdhci_pci'";
    #   };
    # };


    programs.gpt-dictate.enable = true;

    # The ALC285 defaults to maximum capture gain plus 30 dB mic boost on this
    # laptop, which clips the internal microphone into unrecognizable noise.
    systemd.user.services.realtek-internal-mic-gain = {
      description = "Set sane Realtek internal microphone gain";
      wantedBy = ["graphical-session.target"];
      after = ["pipewire.service" "wireplumber.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "realtek-internal-mic-gain" ''
          ${pkgs.alsa-utils}/bin/amixer -c PCH sset 'Internal Mic Boost' 0,0
          ${pkgs.alsa-utils}/bin/amixer -c PCH sset Capture 33,33 cap
        '';
      };
    };

    users.users.dazza = {
      isNormalUser = true;
      description = "Daren Drahos";
      extraGroups = ["networkmanager" "wheel"];
      packages = with pkgs; [
      ];
    };

    environment.systemPackages = with pkgs; [
      baobab
      wireshark
      dig
      net-tools
      pangolin-cli
      xournalpp
      termshark
      wireshark
      (import inputs.nixpkgs-packet-tracer {
        system = pkgs.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      }).cisco-packet-tracer_9

    ];

    system.stateVersion = "25.05"; # Did you read the comment?
  };
}
