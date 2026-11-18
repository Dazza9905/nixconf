{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.printing = {
    pkgs,
    lib,
    ...
  }: {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    services.printing = {
      enable = true;
      drivers = with pkgs; [
        cups-filters
        cups-browsed
      ];
    };

    # Installed but not auto-started — use printing-on / printing-off to manage
    systemd.services.avahi-daemon.wantedBy = lib.mkForce [];
    systemd.sockets.cups.wantedBy = lib.mkForce [];

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "printing-on" ''
        sudo systemctl start avahi-daemon cups
      '')
      (pkgs.writeShellScriptBin "printing-off" ''
        sudo systemctl stop cups avahi-daemon
      '')
    ];
  };
}
