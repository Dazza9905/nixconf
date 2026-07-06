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
        echo "Changes:"
        "$git" diff --stat
        echo "NixOS Rebuilding..."
        if sudo nixos-rebuild switch --flake . &>"$LOG"; then
            current=$(nixos-rebuild list-generations | awk '$NF=="True" {print "gen " $1 " (" $2 " " $3 ")"}')
            echo "Current generation: $current"
            "$git" commit -am "$current"
            "$notify_send" -e "NixOS Rebuilt OK!" --icon=software-update-available
        else
            echo "Rebuild failed, errors below:"
            grep --color=always -i error "$LOG" || cat "$LOG"
            ERR_SUMMARY=$(grep -i error "$LOG" | head -n 3)
            "$notify_send" -u critical -e "NixOS Rebuild Failed" "''${ERR_SUMMARY:-Check $LOG for details}"
            popd >/dev/null
            exit 1
        fi
        popd >/dev/null
      '';
    };
  };
}
