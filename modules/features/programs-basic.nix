{
  self,
  inputs,
  ...
}: {
  perSystem = {pkgs, ...}: {
    packages.clipboardImageEditor = pkgs.writeShellApplication {
      name = "edit-clipboard-image";
      runtimeInputs = [pkgs.satty pkgs.wl-clipboard pkgs.libnotify pkgs.coreutils];
      text = ''
        image=$(mktemp)
        trap 'rm -f "$image"' EXIT
        if ! wl-paste --type image --no-newline > "$image" || [ ! -s "$image" ]; then
          notify-send "Clipboard Image Editor" "Copy an image first, then try again."
          exit 1
        fi
        satty --filename "$image"
      '';
    };
  };

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

    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    users.users.${username} = {
      packages = with pkgs; [
        # self.packages.${pkgs.stdenv.hostPlatform.system}.myHelix
        github-cli
        kitty
        anki
        vesktop
        playerctl
        claude-code
        anki
        playerctl
        beeper
        gparted
        claude-code
        tuios
      ];
    };
    environment.systemPackages = with pkgs; [
      self.packages.${pkgs.stdenv.hostPlatform.system}.clipboardImageEditor
      satty
      wl-clipboard
      github-cli
      kitty
      anki
      vesktop
      playerctl
      anki
      playerctl
      beeper
      gparted
      pciutils
      lazygit
      neovim
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
      t3code
      bitwarden-desktop
      bitwarden-cli
      cliamp
      codex
    ];
  };
}
