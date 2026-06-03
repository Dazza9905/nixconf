{ self, inputs, ... }: {
  flake.nixosConfigurations.dazzapc = inputs.nixpkgs.lib.nixosSystem {
  specialArgs = { inherit inputs; }; 
    modules = [
      self.nixosModules.dazzapcConfiguration
    ];
  };
}
