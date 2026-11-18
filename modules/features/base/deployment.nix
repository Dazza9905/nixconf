{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.deployment = {
    pkgs,
    lib,
    ...
  }: let
    system = pkgs.stdenv.hostPlatform.system;
  in {
    environment.systemPackages = [
      inputs.colmena.packages.${system}.colmena
      # self.packages.${system}.rebuild
      # self.packages.${system}.deploy
    ];

    # colmena deploys as root over SSH; key-only — password login for root stays impossible
    services.openssh.settings.PermitRootLogin = lib.mkForce "prohibit-password";
    services.openssh.settings.AllowUsers = ["root"];
    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICoX8q4oyO5E5lMUYnrFzFgSvSbHeZ8G7WkM42wBFYe2"
    ];
  };
}
