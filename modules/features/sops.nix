{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.sops = {
      pkgs,
      ...
    }: {
    imports = [
      inputs.sops-nix.nixosModules.sops
    ];

    sops.defaultSopsFormat = "yaml";

    sops.age = {
      keyFile = "/var/lib/sops-nix/keys.txt";
      sshKeyPaths = [];
    };
    sops.gnupg.sshKeyPaths = [];

    environment.systemPackages = with pkgs; [
      age
      sops
    ];



  };
}
