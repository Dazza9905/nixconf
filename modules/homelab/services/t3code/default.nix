{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  cfg = config.homelab.services.t3code;
  userHome = config.users.users.${cfg.user}.home;
in
{
# =======================================================
# OPTIONS
# =======================================================
  options.homelab.services.t3code = {
    enable = lib.mkEnableOption "T3 Code backend";

    user = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Existing user whose projects and credentials T3 uses.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address on which the backend listens.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3773;
      description = "Port on which the backend listens.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional tools available to T3 and its agents.";
    };
  };

# =======================================================
# CONFIG
# =======================================================
  config = lib.mkIf cfg.enable {
    users.users.${cfg.user}.linger = true;
    networking.firewall.allowedTCPPorts = [cfg.port];

    systemd.user.services.t3code = {
      description = "T3 Code backend";
      wantedBy = ["default.target"];
      unitConfig.ConditionUser = cfg.user;
      environment.LD_LIBRARY_PATH = lib.makeLibraryPath (with pkgs; [
        glib nspr nss atk at-spi2-atk at-spi2-core dbus
        libx11 libxcomposite libxdamage libxext libxfixes libxrandr
        libgbm expat libxcb libxkbcommon systemd alsa-lib
      ]);
      path = [
        "/etc/profiles/per-user/${cfg.user}"
        "/run/current-system/sw"
        "${userHome}/.nix-profile"
        "${userHome}/.local"
        pkgs.git
        pkgs.openssh
        pkgs.bash
        pkgs.coreutils
      ] ++ cfg.extraPackages;

      serviceConfig = {
        WorkingDirectory = "%h";
        ExecStart = "${pkgs.t3code}/bin/t3 serve"
          + " --base-dir %h/.t3"
          + " --host ${lib.escapeShellArg cfg.host}"
          + " --port ${toString cfg.port}";
        Restart = "on-failure";
        RestartSec = 5;
        KillMode = "mixed";
      };
    };
  };
}
