{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.kvm;
  component =
    if cfg.role == null
    then "client"
    else cfg.role;
  unit = "rkvm-${component}.service";
  template = "rkvm-${component}.toml";
  toml = pkgs.formats.toml {};
in {
  imports = [inputs.sops-nix.nixosModules.sops];

  options.homelab.services.kvm = {
    enable = lib.mkEnableOption "keyboard and mouse sharing with rkvm";
    role = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["server" "client"]);
      default = null;
      description = "Server captures physical input; client receives it.";
    };
    serverAddress = lib.mkOption {
      type = lib.types.str;
      description = "Address of the rkvm server: its listen IP on the server, or its IP/hostname on the client. Bracket IPv6 addresses.";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 5258;
      description = "rkvm TCP port.";
    };
    switchKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["left-alt" "left-ctrl"];
      description = "Server hotkey cycling between local input and connected clients.";
    };
    allowedSubnet = lib.mkOption {
      type = lib.types.str;
      description = "IPv4 LAN subnet allowed to connect to the server, in CIDR notation.";
    };
    certificate = lib.mkOption {
      type = lib.types.path;
      description = "Public TLS certificate trusted by both hosts; must cover the server address.";
    };
    passwordSopsFile = lib.mkOption {
      type = lib.types.path;
      description = "Sops YAML containing rkvm/password, encrypted for both hosts.";
    };
    keySopsFile = lib.mkOption {
      type = lib.types.path;
      description = "Server-only sops YAML containing rkvm/key (PEM private key).";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = cfg.role != null;
          message = "homelab.services.kvm.role must explicitly select server or client.";
        }
      ];
      # Both roles use evdev/uinput as root, independently of greetd and Niri.
      hardware.uinput.enable = true;
      services.rkvm.${component} = {
        enable = true;
        settings = {
          certificate = cfg.certificate;
          password = config.sops.placeholder."rkvm/password";
        };
      };
      sops.secrets."rkvm/password" = {
        sopsFile = cfg.passwordSopsFile;
        restartUnits = [unit];
      };
      # The stock module puts TOML in the store. Only a placeholder goes there;
      # sops substitutes the password into a root-only file at activation/boot.
      sops.templates.${template} = {
        file = toml.generate template config.services.rkvm.${component}.settings;
        restartUnits = [unit];
      };
      systemd.services."rkvm-${component}" = {
        after = ["systemd-modules-load.service" "sops-install-secrets.service"];
        serviceConfig.ExecStart =
          lib.mkForce
          "${config.services.rkvm.package}/bin/rkvm-${component} ${config.sops.templates.${template}.path}";
        # Keep retrying if the LAN/server is unavailable for a long time.
        startLimitIntervalSec = 0;
      };
    }
    (lib.mkIf (cfg.role == "server") {
      services.rkvm.server.settings = {
        listen = "${cfg.serverAddress}:${toString cfg.port}";
        switch-keys = cfg.switchKeys;
        key = config.sops.secrets."rkvm/key".path;
      };
      sops.secrets."rkvm/key" = {
        sopsFile = cfg.keySopsFile;
        restartUnits = [unit];
      };
      # Only the transmitter listens. No global port opening or client rule.
      networking.firewall = lib.mkMerge [
        (lib.mkIf (!config.networking.nftables.enable) {
          extraCommands = ''
            iptables -A nixos-fw -s ${lib.escapeShellArg cfg.allowedSubnet} -p tcp --dport ${toString cfg.port} -j nixos-fw-accept
          '';
        })
        (lib.mkIf config.networking.nftables.enable {
          extraInputRules = ''
            ip saddr ${cfg.allowedSubnet} tcp dport ${toString cfg.port} accept
          '';
        })
      ];
    })
    (lib.mkIf (cfg.role == "client") {
      services.rkvm.client.settings.server = "${cfg.serverAddress}:${toString cfg.port}";
      # Start asynchronously and use the stock Restart=always/RestartSec=5.
      # Waiting for Wi-Fi or the server must not delay the greeter.
      systemd.services.rkvm-client = {
        wants = lib.mkForce [];
        after = lib.mkForce [
          "network.target"
          "systemd-modules-load.service"
          "sops-install-secrets.service"
        ];
      };
    })
  ]);
}
