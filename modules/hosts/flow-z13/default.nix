{ self, inputs, ... }: {
  flake.nixosConfigurations.flow-z13 = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { 
      inherit inputs;
      username = "dazza";
    }; 
    modules = [
      self.nixosModules.flowz13Configuration
    ];
  };
}
