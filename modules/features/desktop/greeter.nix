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
}
