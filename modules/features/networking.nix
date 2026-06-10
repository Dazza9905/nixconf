{ self, inputs, ... }: {
  flake.nixosModules.networking = { pkgs, lib, ... }: {
        services.netbird.clients.wt0 = {

        # Port used to listen to wireguard connections
        port = 51821;

        # Set this to true if you want the GUI client
        ui.enable = false;

        # This opens ports required for direct connection without a relay
        openFirewall = true;

        # This opens necessary firewall ports in the Netbird client's network interface
        openInternalFirewall = true;
    };
  };
}
