{ config, lib, pkgs, ... }:
let
  homelab = config.homelab;
  cfg = homelab.services.immich;

  immichBackup = pkgs.writeShellApplication {
    name = "backup-image";
    runtimeInputs = [
      pkgs.rclone pkgs.util-linux pkgs.coreutils pkgs.gzip pkgs.systemd
      config.services.postgresql.package
    ];
    text = ''
      export BACKUP_ROOT=${lib.escapeShellArg homelab.mount}
      export MEDIA_DIR=${lib.escapeShellArg cfg.mediaDir}
      if [[ -z "''${RCLONE_CONFIG:-}" ]]; then
        export RCLONE_CONFIG=${lib.escapeShellArg homelab.services.backup.rcloneConfig}
      fi
      ${builtins.readFile ./immich-backup.sh}
    '';
  };
in
{
  options.homelab.services.immich.backup.enable =
    lib.mkEnableOption "scheduled nightly Immich database and media backups";

  config = lib.mkIf cfg.enable {
    # Keep the manual command available when the nightly timer is disabled.
    environment.systemPackages = [ immichBackup ];

    systemd.services.immich-backup = lib.mkIf cfg.backup.enable {
      description = "Back up Immich database and media to Backblaze";
      startAt = "*-*-* 02:00:00 ${homelab.timeZone}";
      after = [ "network-online.target" "postgresql.service" ];
      wants = [ "network-online.target" ];
      unitConfig.RequiresMountsFor = [ homelab.mount ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe immichBackup;
      };
    };
  };
}
