{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.ssh = {
    pkgs,
    lib,
    username,
    ...
  }: {
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PasswordAuthentication = true;
        KbdInteractiveAuthentication = true;
        PermitRootLogin = "no";
        AllowUsers = ["dazza"];
        MaxAuthTries = 3;
        PerSourcePenalties = "crash:3600s authfail:3600s max:86400s";
      };
    };
    users.users.${username}.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICoX8q4oyO5E5lMUYnrFzFgSvSbHeZ8G7WkM42wBFYe2"
    ];
  };
}
