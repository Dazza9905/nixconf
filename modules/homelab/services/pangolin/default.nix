{ config, lib, pkgs, username, ... }:
let
  cfg = config.homelab.services.pangolin;
in
{
  options.homelab.services.pangolin = {
    enable = lib.mkEnableOption "Pangolin VPN client";
    user = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "User whose existing Pangolin login the client uses.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.pangolin-cli ];
    systemd.services.pangolin-client = {
      description = "Pangolin VPN client";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      # The tunnel needs root; SUDO_USER selects the existing user's login.
      environment.SUDO_USER = cfg.user;
      path = [ pkgs.iproute2 pkgs.systemd ];
      serviceConfig = {
        ExecStart = "${pkgs.pangolin-cli}/bin/pangolin up client --attach";
        Restart = "always";
        RestartSec = 5;
        UMask = "0077";
      };
    };
  };
}
