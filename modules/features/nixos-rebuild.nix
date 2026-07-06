{...}: {
  perSystem = {
    pkgs,
    lib,
    slef',
    ...
  }: {
    packages.nixos-rebuild-helper = pkgs.writeShellApplication {
      name = "rebuild";
      excludeShellChecks = ["SC2024"];
      text = ''
        alejandra="${lib.getExe pkgs.alejandra}"
        notify_send="${lib.getExe' pkgs.libnotify "notify-send"}"
        git="${lib.getExe pkgs.git}"
        grep="${lib.getExe' pkgs.gnugrep "grep"}"

        CONFIG_DIR="$HOME/.nixconf/"
        LOG="/tmp/nixos-switch.log"

        pushd "$CONFIG_DIR" >/dev/null

        echo "Formatting nix files..."
        "$alejandra" . &>/dev/null || {
            "$alejandra" .
            echo "formatting failed!"
            "$notify_send" -u critical -e "NixOS Rebuild" "Formatting failed"
            popd >/dev/null
            exit 1
        }

        echo "NixOS Rebuilding..."
        if sudo nixos-rebuild switch --flake . &>"$LOG"; then
          current=$(nixos-rebuild list-generations | "$grep" -i current || true)
          if [ -z "$current" ]; then
              echo "Warning: couldn't determine current generation, using fallback message"
              current="nixos rebuild $(date -Is)"
          fi
          "$git" commit -am "$current"
        else
            echo "Rebuild failed, errors below:"
            "$grep" --color=always -i error "$LOG" || cat "$LOG"
            ERR_SUMMARY=$("$grep" -i error "$LOG" | head -n 3)
            "$notify_send" -u critical -e "NixOS Rebuild Failed" "''${ERR_SUMMARY:-Check $LOG for details}"
            popd >/dev/null
            exit 1
        fi

        popd >/dev/null
      '';
    };
  };
}
