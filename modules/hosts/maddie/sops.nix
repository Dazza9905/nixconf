{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.maddieSops = {

    imports = [
      self.nixosModules.sops
    ];

    sops.defaultSopsFile = ../../../secrets/maddie.yaml;
  };
}
