{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.dazzapc = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs;
      username = "dazza";
    };
    modules = [
      self.nixosModules.dazzapcConfiguration
    ];
  };
}
