{
  self,
  inputs,
  ...
}: {
  perSystem = {pkgs, ...}: let
    wlib = inputs.wrappers.lib;
  in {
    packages.myT3code = wlib.wrapPackage {
      inherit pkgs;
      package = pkgs.t3code;
      exePath = "${pkgs.t3code}/bin/t3code-desktop";
      runtimeInputs = [pkgs.jq pkgs.coreutils];
      preHook = ''
        settings="''${T3CODE_HOME:-$HOME/.t3}/userdata/desktop-settings.json"
        mkdir -p "$(dirname "$settings")"
        tmp="$(mktemp "$settings.XXXXXX")"
        trap 'rm -f "$tmp"' EXIT

        if [ -f "$settings" ]; then
          jq '.localEnvironmentEnabled = false' "$settings" > "$tmp" || exit 1
        else
          printf '%s\n' '{"localEnvironmentEnabled":false}' > "$tmp"
        fi
        mv "$tmp" "$settings"
      '';
    };
  };

  flake.nixosModules.t3code = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.homelab.services.t3code.enable {
      users.users.${config.homelab.services.t3code.user}.packages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.myT3code
      ];
    };
  };
}
