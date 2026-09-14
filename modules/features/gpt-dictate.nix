{...}: let
  mkPackages = pkgs: rec {
    codex-stt-bridge = pkgs.python3Packages.buildPythonApplication rec {
      pname = "codex-stt-bridge";
      version = "0.2.1";
      pyproject = true;

      src = pkgs.fetchFromGitHub {
        owner = "ai-babai";
        repo = "codex-stt-bridge";
        rev = "v${version}";
        hash = "sha256-DgnW2CY8r4y/xrFwK5tcv2Psg3tOvQkdptQgza6//Gg=";
      };

      build-system = [pkgs.python3Packages.hatchling];
      pythonImportsCheck = ["codex_stt_bridge"];
    };

    gpt-dictate = pkgs.writeShellApplication {
      name = "gpt-dictate";
      runtimeInputs = [pkgs.coreutils pkgs.gnugrep pkgs.kitty pkgs.pipewire pkgs.wtype codex-stt-bridge];
      text = ''
      set -u

      [ "''${1:-}" = toggle ] || { echo "usage: gpt-dictate toggle" >&2; exit 2; }
      state="''${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set}/gpt-dictate"
      pid_file="$state/recording.pid"
      kitty_pid_file="$state/kitty.pid"
      audio="$state/recording.wav"
      status="$state/status"
      error_log="$state/error.log"
      mkdir -p "$state"
      chmod 700 "$state"

      close_status() {
        if [ -s "$kitty_pid_file" ]; then
          kitty_pid=$(cat "$kitty_pid_file")
          case "$kitty_pid" in (*[!0-9]*|"") kitty_pid="";; esac
          if [ -n "$kitty_pid" ] && tr '\0' ' ' <"/proc/$kitty_pid/cmdline" 2>/dev/null | grep -Fq -- 'gpt-dictate'; then
            kill "$kitty_pid" 2>/dev/null || true
          fi
        fi
        rm -f "$kitty_pid_file"
      }

      show_error() {
        printf 'Error: %s\n' "$1" >"$status"
        sleep 3
        close_status
      }

      recording_pid=""
      if [ -s "$pid_file" ]; then
        recording_pid=$(cat "$pid_file")
        case "$recording_pid" in (*[!0-9]*|"") recording_pid="";; esac
        if [ -n "$recording_pid" ] && { ! kill -0 "$recording_pid" 2>/dev/null || ! tr '\0' ' ' <"/proc/$recording_pid/cmdline" 2>/dev/null | grep -Fq -- "$audio"; }; then
          recording_pid=""
        fi
      fi

      if [ -z "$recording_pid" ]; then
        close_status
        rm -f "$pid_file" "$audio" "$error_log"
        printf 'Recording...\n' >"$status"
        # The variables below belong to the inner shell.
        # shellcheck disable=SC2016
        kitty --class gpt-dictate --title 'GPT Dictation' sh -c '
          last=""
          while [ -e "$1" ]; do
            current=$(cat "$1")
            if [ "$current" != "$last" ]; then
              printf "\033[2J\033[H%s\n" "$current"
              last=$current
            fi
            sleep 0.1
          done
        ' sh "$status" &
        echo $! >"$kitty_pid_file"

        pw-record "$audio" </dev/null >/dev/null 2>"$error_log" &
        recording_pid=$!
        echo "$recording_pid" >"$pid_file"
        sleep 0.2
        if ! kill -0 "$recording_pid" 2>/dev/null; then
          rm -f "$pid_file"
          message=$(head -n 1 "$error_log")
          show_error "''${message:-could not start recording}"
          exit 1
        fi
        exit 0
      fi

      rm -f "$pid_file"
      printf 'Transcribing...\n' >"$status"
      kill -INT "$recording_pid" 2>/dev/null || true
      for _ in $(seq 1 50); do
        kill -0 "$recording_pid" 2>/dev/null || break
        sleep 0.1
      done
      kill -TERM "$recording_pid" 2>/dev/null || true

      if [ ! -s "$audio" ]; then
        show_error "no audio was recorded"
        exit 1
      fi
      if ! transcript=$(codex-stt --input "$audio" 2>"$error_log"); then
        message=$(head -n 1 "$error_log")
        show_error "''${message:-transcription failed}"
        exit 1
      fi
      if [ -z "$transcript" ]; then
        show_error "transcription was empty"
        exit 1
      fi

      rm -f "$status" "$audio" "$error_log"
      close_status
      sleep 0.2
      wtype -- "$transcript"
      '';
    };

    desktop-entry = pkgs.makeDesktopItem {
      name = "gpt-dictate";
      desktopName = "GPT Dictation";
      comment = "Toggle speech dictation";
      exec = "gpt-dictate toggle";
      icon = "audio-input-microphone";
      categories = ["Utility" "Accessibility"];
    };
  };

  nixosModule = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.programs.gpt-dictate;
    packages = mkPackages pkgs;
  in {
    options.programs.gpt-dictate.enable = lib.mkEnableOption "small, shortcut-driven speech dictation";

    config = lib.mkIf cfg.enable {
      environment.systemPackages = with packages; [gpt-dictate codex-stt-bridge desktop-entry pkgs.pipewire pkgs.wtype pkgs.kitty];
    };
  };
in {
  perSystem = {pkgs, ...}: let
    packages = mkPackages pkgs;
  in {
    packages = packages // {default = packages.gpt-dictate;};
  };

  flake.nixosModules.gpt-dictate = nixosModule;
}
