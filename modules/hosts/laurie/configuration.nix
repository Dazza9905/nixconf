{
  self,
  inputs,
  ...
}: {
  flake.nixosModules."laurieConfiguration" = {
    pkgs,
    lib,
    username,
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
      self.nixosModules.remoteDesktop
      self.nixosModules.homelab
      self.nixosModules.sops
      self.nixosModules.dns

      self.nixosModules.games
      self.nixosModules."programs-3d"
    ];

    # ==================================================================
    # UNIFIED CONFIGURATION
    # ==================================================================
    settings = {
      enable = true;
      remoteDesktop = {
        client = true;
      };
    };

    homelab.services = {
      pangolin.enable = true;
      newt = {
        enable = true;
      };

      t3code = {
        enable = true;
        user = username;
        host = "0.0.0.0";
        port = 3773;
        extraPackages = with pkgs; [
          python3
          uv
          nodejs
          sqlite
          jq
          file
          binutils
          poppler-utils
          psmisc
          patchelf
          ripgrep
        ];
      };

      kvm = {
        enable = true;
        role = "client";
        serverAddress = "192.168.100.26";
        certificate = ../../../secrets/rkvm-certificate.pem;
        passwordSopsFile = ../../../secrets/rkvm.yaml;
      };
    };

    sops.defaultSopsFile = ../../../secrets/laurie.yaml;
    # ==================================================================
    # OTHER
    # ==================================================================
    networking.hostName = "laurie";

    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINt6vCBvTYA+fRDNxAHc9TmYDP/eAaUlCBBsK5AUM5Ym"
    ];

    programs = {
      wireshark.enable = true;
      gpt-dictate.enable = true;
    };

    services.gnome.core-apps.enable = true;
    users.users.dazza = {
      isNormalUser = true;
      description = "Daren Drahos";
      extraGroups = ["networkmanager" "wheel" "wireshark"];
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
      obsidian
      cisco-packet-tracer_9
      activate-linux
    ];

    # Mount only on access; return errors when offline instead of retrying forever.
    # Interrupted writes can fail or leave incomplete files.
    fileSystems = let
      nasOptions = [
        "noauto"
        "nofail"
        "x-systemd.automount"
        "x-systemd.mount-timeout=30s"
        "x-systemd.idle-timeout=15min"
        "softerr"
        "timeo=20"
        "retrans=2"
      ];
    in {
      "/mnt/nas" = {
        device = "192.168.100.21:/mnt/860evo/files-dazza";
        fsType = "nfs";
        options = nasOptions;
      };
      "/mnt/nas-raw" = {
        device = "192.168.100.21:/mnt/";
        fsType = "nfs";
        options = nasOptions;
      };
    };


    # ==================================================================
    # WORKAROUNDS
    # ==================================================================
    # -------------------
    # DNS SHENANIGANS
    # -------------------
    services.dnsproxy = {
      enable = true;
      settings = {
        listen-addrs = ["192.0.2.53"];
        listen-ports = [53];
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
      requires = ["network-addresses-lo.service"];
      after = ["network-addresses-lo.service"];
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
    networking = {
      networkmanager = {
        enable = true;
        # Keep DHCP DNS out of resolved: dnsproxy handles FIIT explicitly.
        dns = lib.mkForce "none";
        settings.main.systemd-resolved = false;
      };
      # Pangolin ignores 127.0.0.0/8 when discovering upstream resolvers.
      # This address stays on lo; it is not a DNS server exposed on Wi-Fi.
      interfaces.lo.ipv4.addresses = [
        {
          address = "192.0.2.53";
          prefixLength = 32;
        }
      ];
      nameservers = ["192.0.2.53"];
    };


    # ==================================================================
    # LAURIE HARDWARE STUFF
    # ==================================================================
    # -------------------
    # CPU
    # -------------------
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

    # -------------------
    # SD CARD
    # -------------------
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

    # -------------------
    # MICROPHONE
    # -------------------
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

    # -------------------
    # SUSPEND
    # -------------------
    # suspend on lid close (logind defaults to ignore on Wayland without a DE)
    services.logind = {
      lidSwitch = "suspend";
      lidSwitchExternalPower = "suspend";
    };

    # -------------------
    # BATTERY
    # -------------------
    # battery and asus stuff
    services.upower.enable = true;
    services.asusd.enable = true;

    # -------------------
    # BOOTLOADER
    # -------------------
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.timeout = 1;
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # faster initrd: zstd compression (systemd stage-1 is now mandatory)
    boot.initrd.compressor = "zstd";

    # skip waiting for a full network connection before declaring boot done
    systemd.services.NetworkManager-wait-online.enable = false;

    # -------------------
    # GRAPHICS
    # -------------------
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
      extraPackages = with pkgs; [
        intel-compute-runtime
      ];
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
    # supergfxd persists the GPU mode across reboots in /etc/asusd/supergfxd.conf
    # do NOT set a default mode here so manual changes (Integrated/Hybrid/etc.) survive rebuilds
    services.supergfxd.enable = true;

    system.stateVersion = "25.05"; # Did you read the comment?
  };
}
