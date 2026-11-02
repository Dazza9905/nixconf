{
  self,
  moduleWithSystem,
  ...
}: {
  flake.nixosModules.programs-basic = moduleWithSystem ({self', ...}: {
    pkgs,
    lib,
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

    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    users.users.${username} = {
      packages = with pkgs; [
        # self.packages.${pkgs.stdenv.hostPlatform.system}.myHelix
      ];
    };
    environment.systemPackages = with pkgs; [
      self'.packages.mySuperfile
      self'.packages.clipboardImageEditor
      satty
      wl-clipboard
      github-cli
      kitty
      anki
      vesktop
      playerctl
      anki
      beeper
      gparted
      pciutils
      lazygit
      neovim
      nixd
      alejandra
      tree-sitter
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
      bitwarden-desktop
      bitwarden-cli
      codex
      obsidian
    ];
  });
}
