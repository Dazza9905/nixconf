{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.enviroment = {
    pkgs,
    lib,
    username,
    ...
  }: {
    imports = [
      self.nixosModules.fonts
      self.nixosModules.programs-basic
    ];

    programs.fish.enable = true;
    users.extraUsers.${username} = {
      shell = pkgs.fish;
    };
  };
}
