{ self, inputs, ... }: {
  flake.nixosModules.homelab = {
    lib,
    config,
    ...
  }: {
# =======================================================
# IMPORTS
# =======================================================
    imports = [
      ./services
      self.nixosModules.t3code
      self.nixosModules.hosts
    ];
# =======================================================
# OPTIONS
# =======================================================
    options.homelab = {
      enable = lib.mkEnableOption "machine and services configuration for homelab stuff";
      
      mount = lib.mkOption {
        default = "/mnt/nas";
        type = lib.types.str;
        description = "path to the main mount";
      };
      
      user = lib.mkOption {
        default = "dazza";
        type = lib.types.str;
        description = "the user of user";
      };
      group = lib.mkOption {
        default = "dazza";
        type = lib.types.str;
        description = "the group of user";
      };

      service_user = lib.mkOption {
        default = "homelab";
        type = lib.types.str;
        description = "user under which services run";
      };
      service_group = lib.mkOption {
        default = "homelab";
        type = lib.types.str;
        description = "group under which services run";
      };

      timeZone = lib.mkOption {
        default = "Europe/Bratislava";
        type = lib.types.str;
        description = "time zone for services";
      };
      baseDomain = lib.mkOption {
        default = "dazza9905.me";
        type = lib.types.str;
        description = "baseDomain";
      };

      host = {
        ip = lib.mkOption {
          type = lib.types.str;
          description = "ip of the current host system";
        };

        hostname = lib.mkOption {
          type = lib.type.str;
          description = "hostname of the current host system";
        };
        type = lib.types.submodule {
          options = {
            system = lib.mkOption { type = lib.types.str; };
            targetHost = lib.mkOption { type = lib.types.str; };
            targetUser = lib.mkOption { type = lib.types.str; };
            tags = lib.mkOption { type = lib.types.listOf lib.types.str; };
            allowLocalDeployment = lib.mkOption { type = lib.types.bool; };
          };
        };
      };
    };
# =======================================================
# CONFIG
# =======================================================
    config = lib.mkIf config.homelab.enable {
      users = {
        groups.${config.homelab.service_group} = {
          gid = 950;
        };
        users.${config.homelab.service_user} = {
          uid = 950;
          isSystemUser = true;
          group = config.homelab.service_group;
        };

        groups.${config.homelab.group} = {
          gid = 1000;
        };
        users.${config.homelab.user} = {
          uid = 1000;
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          group = config.homelab.group;
        };
      };
      security.sudo.wheelNeedsPassword = true;
    };
  };
}
