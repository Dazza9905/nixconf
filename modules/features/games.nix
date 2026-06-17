{ self, inputs, ... }: {
  flake.nixosModules.games = { pkgs, lib, username, ... }: {
    users.users.${username}.packages = with pkgs; [
      moonlight-qt
    ];
  };
}
