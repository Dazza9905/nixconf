{ self, inputs, ... }: {
  flake.nixosConfiguration.flow-z13 = inputs.nixpkgs.lib.nixosSystem {
    module = [
      self.nixosModules.flowz13Configuration
      self.nixosModules.plasma
    ];
  };
}
