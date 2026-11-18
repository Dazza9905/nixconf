{
  config,
  lib,
  ...
}:
let
  homelab = config.homelab;
  cfg = homelab.services.ssh;
in
{
# =======================================================
# IMPORTS
# =======================================================
# =======================================================
# OPTIONS
# =======================================================
  options.homelab.services.ssh = {
    enable = lib.mkEnableOption "Enable ssh";
  };
# =======================================================
# CONFIG
# =======================================================
  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        AllowUsers = ["dazza"];
        MaxAuthTries = 3;
        PerSourcePenalties = "crash:3600s authfail:3600s max:86400s";
      };
    };

    users.users.${homelab.user}.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICoX8q4oyO5E5lMUYnrFzFgSvSbHeZ8G7WkM42wBFYe2"
    ];

    # =======================================================
    # SOPS
    # =======================================================
  };

}
