{
  self,
  inputs,
  ...
}: {
  flake.nixosModules."programs-3d" = {
    pkgs,
    username,
    ...
  }: {
    users.users.${username}.packages = with pkgs; [
      blender
      prusa-slicer
      plasticity
    ];
  };
}
