{...}: {
  perSystem = {pkgs, lib, ...}: let
    configDir = pkgs.runCommand "noctalia-config" {} ''
      mkdir -p $out/noctalia
      cp ${./noctalia-config.toml} $out/noctalia/config.toml
      ${lib.getExe pkgs.noctalia} config validate $out/noctalia/config.toml
    '';
    revision = builtins.hashString "sha256" "${pkgs.noctalia}:${configDir}";
  in {
    packages.myNoctalia = pkgs.writeShellApplication {
      name = "noctalia";
      runtimeInputs = [pkgs.coreutils pkgs.util-linux];
      text = ''
        export NOCTALIA_CONFIG_HOME=${configDir}
        # Only shell startup changes state; export, validation and IPC do not.
        if [[ $# -eq 0 || "''${1:-}" == --daemon || "''${1:-}" == -d ]]; then
          state="''${NOCTALIA_STATE_HOME:-''${XDG_STATE_HOME:-$HOME/.local/state}}/noctalia"
          mkdir -p "$state"
          (
            flock 9
            previous=$(cat "$state/.declarative-revision" 2>/dev/null || true)
            if [[ "$previous" != ${revision} ]]; then
              if [[ -e "$state/settings.toml" || -L "$state/settings.toml" ]]; then
                backup=$(mktemp -d "$state/settings-backup.XXXXXXXX")
                mv "$state/settings.toml" "$backup/settings.toml"
              fi
              printf '%s\n' ${revision} > "$state/.declarative-revision"
            fi
          ) 9> "$state/.declarative-lock"
        fi
        exec ${lib.getExe pkgs.noctalia} "$@"
      '';
    };
  };
}
