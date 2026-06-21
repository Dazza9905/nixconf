{ self, inputs, ... }: {
  flake.nixosModules.audiorelay = { pkgs, lib, username, ... }: {
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 59100 ];
      allowedUDPPorts = [ 59100 59200 ];
    };
  };
}
