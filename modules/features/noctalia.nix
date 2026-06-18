{ self, inputs, ... }: {
  perSystem = { pkgs, ... }: {
    # packages.myNoctalia = 
    # let
    #   raw = builtins.fromJSON (builtins.readFile ./noctalia.json);
    #   _ = builtins.trace "settings: ${builtins.toJSON raw.settings}" null;
    # in
    # inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
    #   inherit pkgs;
    #   settings = raw.settings;
    # };  
    packages.myNoctalia = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
      inherit pkgs; # THIS PART IS VERY IMPORTAINT, I FORGOT IT IN THE VIDEO!!!
      settings =
        (builtins.fromJSON
          (builtins.readFile ./noctalia.json)).settings;
    };
  };
}
