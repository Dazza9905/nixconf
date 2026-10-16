{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.greeter = {
    pkgs,
    lib,
    ...
  }: {
    programs.noctalia-greeter.enable = true;
    # Temporarily use the standard greeter while touch-keyboard support is in progress.
    # services.displayManager.noctalia-greeter.package = self.packages.${pkgs.stdenv.hostPlatform.system}.touch-greeter;

    services.gnome.gnome-keyring.enable = true;
    services.udisks2.enable = true;

    # This allows your login password to unlock the keyring automatically
    security.pam.services.greetd.enableGnomeKeyring = true;

    # Ensure the DBus service is visible to Niri
    systemd.user.services.gnome-keyring = {
      description = "GNOME Keyring";
      serviceConfig = {
        ExecStart = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --foreground --components=secrets";
        Restart = "on-abort";
      };
      wantedBy = ["graphical-session.target"];
    };
  };
  perSystem = {pkgs, ...}: {
    packages.touch-greeter = (pkgs.callPackage "${inputs.noctalia-greeter}/nix/package.nix" {}).overrideAttrs (old: {
      patches = (old.patches or []) ++ [./touch/greeter-osk.patch];
      postPatch = (old.postPatch or "") + ''
        cp ${./touch/greeter-keyboard.inc} src/greeter/touch_keyboard.inc
      '';
    });
  };
}
