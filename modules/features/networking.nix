{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.networking = {
    pkgs,
    lib,
    username,
    ...
  }: {
    services.netbird.clients.wt0 = {
      port = 51821;
      ui.enable = false;
      openFirewall = true;
      openInternalFirewall = true;
    };

    users.users.${username}.extraGroups = ["netbird-wt0"];

    #map origo command
    systemd.tmpfiles.rules = [
      "d /var/run/netbird 0755 root root -"
      "L+ /var/run/netbird.sock - - - - /var/run/netbird-wt0/sock"
    ];

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "netbird" ''
        exec /run/current-system/sw/bin/netbird-wt0 "$@"
      '')
    ];
  };
}
