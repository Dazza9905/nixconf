{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.nix-settings = {
    pkgs,
    lib,
    username,
    ...
  }: {
    nix.settings.auto-optimise-store = true;
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    nix.settings.trusted-users = ["root" "${username}"];
    nixpkgs.config.allowUnfree = true;

    nixpkgs.overlays = [
      (final: prev: {
        # Pin Moonlight to ffmpeg 8: its Vulkan renderer does not yet support
        # ffmpeg 9's AVVulkanDeviceContext API changes.
        moonlight-qt = prev.moonlight-qt.override {ffmpeg_8 = prev.ffmpeg_8;};
      })
    ];

    programs.nix-ld.enable = true;

    nix.settings.experimental-features = ["nix-command" "flakes"];
  };
}
