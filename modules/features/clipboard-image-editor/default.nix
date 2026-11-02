{...}: {
  perSystem = {pkgs, lib, ...}: {
    packages.clipboardImageEditor = pkgs.writeShellApplication {
      name = "edit-clipboard-image";
      runtimeInputs = [pkgs.satty pkgs.wl-clipboard pkgs.libnotify pkgs.coreutils];
      text = ''
        image=$(${lib.getExe' pkgs.coreutils "mktemp"})
        trap '${lib.getExe' pkgs.coreutils "rm"} -f "$image"' EXIT
        if ! ${lib.getExe' pkgs.wl-clipboard "wl-paste"} --type image --no-newline > "$image" || [ ! -s "$image" ]; then
          ${lib.getExe' pkgs.libnotify "notify-send"} "Clipboard Image Editor" "Copy an image first, then try again."
          exit 1
        fi
        ${lib.getExe pkgs.satty} --filename "$image"
      '';
    };
  };
}
