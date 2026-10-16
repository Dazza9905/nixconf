"""Permanent Noctalia bar controls and reversible Niri touch scaling."""

import fcntl
import json
import os
from pathlib import Path
import shutil
import shlex
import subprocess
import sys
import tempfile

import tomlkit


STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
SETTINGS = STATE / "noctalia/settings.toml"
RUNTIME = Path(os.environ["XDG_RUNTIME_DIR"]) / "touch-controls"
SCALES = RUNTIME / "scales.json"
FACTOR = 1.25
KEYBOARD_ARGS = [
    "--non-exclusive", "--margin", "20", "--width-ratio", "65",
    "--border", "2", "--padding", "24", "--corner", "16",
    "-H", "320", "-L", "320", "--no-popup",
]


def run(*args, check=True):
    return subprocess.run(args, check=check, text=True, capture_output=True)


def niri(*args):
    return json.loads(run("niri", "msg", "--json", *args).stdout)


def read_toml(path):
    return tomlkit.parse(path.read_text()) if path.exists() else tomlkit.document()


def atomic_write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(dir=path.parent, prefix=f".{path.name}.")
    try:
        with os.fdopen(fd, "w") as output:
            output.write(text)
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def install_bar():
    # Noctalia keeps GUI overrides here; preserve all unrelated settings.
    # The declarative file supplies bar definitions absent from the override.
    base = read_toml(CONFIG / "noctalia/noctalia-config.toml")
    settings = read_toml(SETTINGS)
    bars = settings.setdefault("bar", tomlkit.table())
    base_bars = base.get("bar", {})
    order = bars.get("order", base_bars.get("order", ["default"]))
    for name in order:
        bar = bars.setdefault(name, tomlkit.table())
        end = list(bar.get("end", base_bars.get(name, {}).get("end", [])))
        for widget in ("touch-keyboard", "touch-mode"):
            if widget not in end:
                end.insert(end.index("tray") if "tray" in end else len(end), widget)
        bar["end"] = end

    widgets = settings.setdefault("widget", tomlkit.table())
    command = shlex.quote(os.environ.get("TOUCH_CONTROLS_COMMAND", "touch-controls"))
    widgets["touch-keyboard"] = {
        "type": "custom_button",
        "glyph": "keyboard",
        "tooltip": "Show / hide touch keyboard — drag its top grip to move",
        "actions": {"left": f"exec {command} keyboard"},
    }
    active = SCALES.exists()
    widgets["touch-mode"] = {
        "type": "custom_button",
        "glyph": "hand-finger",
        "label": "+" if active else "",
        "tooltip": "Touch mode: " + ("on — restore normal size" if active else "off — make laptop UI 125% of normal size"),
        "actions": {"left": f"exec {command} scale"},
    }
    text = tomlkit.dumps(settings)
    if SETTINGS.exists() and text == SETTINGS.read_text():
        return
    backup = SETTINGS.with_name("settings.toml.before-touch-controls")
    if SETTINGS.exists() and not backup.exists():
        shutil.copy2(SETTINGS, backup)
    atomic_write(SETTINGS, text)
    # The service can run before Noctalia; its normal startup will load the file.
    run("noctalia", "msg", "config-reload", check=False)


def keyboard():
    active = run("systemctl", "--user", "is-active", "touch-keyboard.service", check=False)
    if active.returncode == 0:
        run("systemctl", "--user", "kill", "--kill-whom=main", "--signal=RTMIN", "touch-keyboard.service")
    else:
        load = run("systemctl", "--user", "show", "--property=LoadState", "--value", "touch-keyboard.service")
        if load.stdout.strip() == "not-found":
            # Also works immediately, before the next NixOS rebuild installs
            # the declarative unit. The transient unit follows this session.
            run(
                "systemd-run", "--user", "--unit=touch-keyboard", "--collect",
                "--property=PartOf=graphical-session.target",
                "--property=Restart=on-failure",
                f"--setenv=WAYLAND_DISPLAY={os.environ['WAYLAND_DISPLAY']}",
                f"--setenv=XDG_RUNTIME_DIR={os.environ['XDG_RUNTIME_DIR']}",
                os.environ["TOUCH_KEYBOARD_EXEC"], *KEYBOARD_ARGS,
            )
        else:
            run("systemctl", "--user", "start", "touch-keyboard.service")


def set_scale(name, scale):
    run("niri", "msg", "output", name, "scale", str(scale))


def scale():
    outputs = niri("outputs")
    outputs = {name: output for name, output in outputs.items() if output.get("logical")}
    if SCALES.exists():
        saved = json.loads(SCALES.read_text())
        if saved["session"] == os.environ.get("NIRI_SOCKET"):
            for name, values in saved["outputs"].items():
                if name in outputs:
                    set_scale(name, values["original"])
            SCALES.unlink()
            install_bar()
            run("notify-send", "Touch mode off", "Restored the previous display scale", check=False)
            return
        SCALES.unlink()

    targets = [name for name in outputs if name.startswith(("eDP-", "LVDS-", "DSI-"))]
    if not targets:
        focused = next((w["output"] for w in niri("workspaces") if w["is_focused"]), None)
        targets = [focused] if focused in outputs else []
    if not targets:
        raise RuntimeError("No active laptop or focused display found")

    saved = {"session": os.environ.get("NIRI_SOCKET"), "outputs": {}}
    for name in targets:
        original = outputs[name]["logical"]["scale"]
        saved["outputs"][name] = {"original": original, "touch": round(original * FACTOR, 3)}
    # Save recovery data before making any compositor changes.
    atomic_write(SCALES, json.dumps(saved))
    try:
        for name, values in saved["outputs"].items():
            set_scale(name, values["touch"])
    except Exception:
        for name, values in saved["outputs"].items():
            set_scale(name, values["original"])
        SCALES.unlink()
        raise
    install_bar()
    run("notify-send", "Touch mode on", "Laptop UI is 125% of normal size", check=False)


def main():
    RUNTIME.mkdir(mode=0o700, parents=True, exist_ok=True)
    with (RUNTIME / "lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        {"install-bar": install_bar, "keyboard": keyboard, "scale": scale}[sys.argv[1]]()


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        message = error.stderr.strip() if isinstance(error, subprocess.CalledProcessError) else str(error)
        print(message, file=sys.stderr)
        run("notify-send", "Touch controls", message, check=False)
        sys.exit(1)
