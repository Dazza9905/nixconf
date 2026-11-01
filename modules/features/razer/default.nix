{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.razer = {
    pkgs,
    lib,
    config,
    username,
    ...
  }: {
# =======================================================
# OPTIONS
# =======================================================
    options.settings.razer = {
      enable = lib.mkEnableOption "razer device support";
    };
# =======================================================
# CONFIG
# =======================================================
    config = lib.mkIf config.settings.razer.enable {
      hardware.openrazer = {
        enable = true;
        users = [ username ];
      };

      environment.systemPackages = [
        pkgs.polychromatic
      ];

      # Override the autostart entry shipped by Polychromatic.
      environment.etc."xdg/autostart/polychromatic-autostart.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Polychromatic Autostart
        Hidden=true
      '';
    };
  };
}
