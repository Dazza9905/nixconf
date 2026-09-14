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
      self.nixosModules.zen
      self.nixosModules.yazi
      self.nixosModules.ncspot
      self.nixosModules.btop
    ];

    programs.localsend = {
      enable = true;
    };

    users.users.${username} = {
      packages = with pkgs; [
             ];
    };
    environment.systemPackages = with pkgs; [
      github-cli
      kitty
      anki
      vesktop
      playerctl
      anki
      playerctl
      beeper
      gparted
      moonlight-qt
      pciutils
      lazygit
      neovim
      git
      stow
      fd
      fzf
      eza
      zip
      unzip
      bat
      nwg-displays
      pavucontrol
      ntfs3g
      dust
      zellij
      ripgrep
      bob-nvim
      zoxide
      starship
      libnotify
      brightnessctl
      devenv
      t3code
      bitwarden-desktop
      bitwarden-cli
      cliamp
      libreoffice
    ];
  };
}
