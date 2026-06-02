{ self, inputs, ... }: {
  perSystem = { pkgs, ... }: {
    packages.myNoctalia = 
  let
    raw = builtins.fromJSON (builtins.readFile ./noctalia.json);
    _ = builtins.trace "settings: ${builtins.toJSON raw.settings}" null;
  in
  inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
    inherit pkgs;
    settings = raw.settings;
  };  };
}
