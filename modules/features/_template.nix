{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.programs-basic = {
    pkgs,
    lib,
    self',
    username,
    ...
  }: {
    imports = [

    ];

    users.users.${username} = {
      packages = with pkgs; [

      ];
    };
    environment.systemPackages = with pkgs; [

    ];
  };
}
