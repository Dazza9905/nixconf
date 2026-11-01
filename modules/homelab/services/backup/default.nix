{ config, lib, pkgs, ... }:
let
  homelab = config.homelab;
  cfg = homelab.services.backup;

  dataBackup = pkgs.writeShellApplication {
    name = "backup-files";
    runtimeInputs = [ pkgs.rclone pkgs.util-linux pkgs.coreutils ];
    text = ''
      export BACKUP_ROOT=${lib.escapeShellArg homelab.mount}
      if [[ -z "''${RCLONE_CONFIG:-}" ]]; then
        export RCLONE_CONFIG=${lib.escapeShellArg cfg.rcloneConfig}
      fi
      ${builtins.readFile ./data-backup.sh}
    '';
  };
in
{
  options.homelab.services.backup = {
    enable = lib.mkEnableOption "scheduled nightly backups of files-dazza and files-patrik";

    # Shared by the files and Immich backups; SOPS renders the credentials at boot.
    rcloneConfig = lib.mkOption {
      type = lib.types.str;
      default = config.sops.templates."rclone.conf".path;
      description = "Path to the rclone config containing the bb-b2 remote.";
    };
  };

  config = lib.mkIf homelab.enable {
    # Keep the manual command available when the nightly timer is disabled.
    environment.systemPackages = [ dataBackup ];

    # Available for manual backups too, even when both nightly timers are off.
    sops.secrets."services/backup/key_id" = {};
    sops.secrets."services/backup/application_key" = {};
    sops.templates."rclone.conf" = {
      owner = "root";
      group = "root";
      mode = "0400";
      content = ''
        [bb-b2]
        type = b2
        account = ${config.sops.placeholder."services/backup/key_id"}
        key = ${config.sops.placeholder."services/backup/application_key"}
      '';
    };

    systemd.services.data-backup = lib.mkIf cfg.enable {
      description = "Back up Dazza and Patrik's files to Backblaze";
      startAt = "*-*-* 03:00:00 ${homelab.timeZone}";
      after = [ "network-online.target" "immich-backup.service" ];
      wants = [ "network-online.target" ];
      unitConfig.RequiresMountsFor = [ homelab.mount ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe dataBackup;
      };
    };
  };
}
