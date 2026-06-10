{ self, inputs, ... }: {
  flake.nixosModules."3d" = { pkgs, username, ... }: {
    users.users.${username}.packages = with pkgs; [
      blender
      prusa-slicer
    ];
  };
}
