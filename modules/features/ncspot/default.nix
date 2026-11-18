{
  self,
  inputs,
  ...
}: {
  perSystem = {
    pkgs,
    lib,
    self',
    ...
  }: let
    wlib = inputs.wrappers.lib;
  in {
    packages.myNcspot = let
      desktopItem = pkgs.makeDesktopItem {
        name = "ncspot";
        desktopName = "ncspot";
        comment = "ncurses Spotify client";
        exec = "${lib.getExe pkgs.kitty} --single-instance --class ncspot -e ncspot";
        icon = "ncspot";
        categories = ["Audio" "Music" "Player" "ConsoleOnly"];
        terminal = false;
        startupWMClass = "ncspot";
        keywords = ["spotify" "music" "player"];
      };
    in
      wlib.wrapPackage {
        inherit pkgs;
        package = pkgs.ncspot;
        runtimeInputs = [pkgs.tmux];
        filesToExclude = ["share/applications/ncspot.desktop"];
        preHook = ''
          CONFIG_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ncspot"
          mkdir -p "$CONFIG_DIR"
          install -m 644 ${./ncspot.toml} "$CONFIG_DIR/config.toml"
          export NCSPOT_CONFIG_DIR="$CONFIG_DIR"
          exec ${pkgs.tmux}/bin/tmux new-session -A -s ncspot ${pkgs.ncspot}/bin/ncspot "$@"
        '';
        patchHook = ''
          mkdir -p $out/share/applications
          cp ${desktopItem}/share/applications/ncspot.desktop \
            $out/share/applications/ncspot.desktop
        '';
      };
  };

  flake.nixosModules.ncspot = {
    pkgs,
    username,
    ...
  }: {
    users.users.${username}.packages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.myNcspot
    ];
  };
}
