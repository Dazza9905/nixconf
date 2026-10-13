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
    # Enable the Noctalia cache even when flake nixConfig is not accepted.
    nix.settings.extra-substituters = ["https://noctalia.cachix.org"];
    nix.settings.extra-trusted-public-keys = ["noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="];
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

        # Electron's backend loads node-pty dynamically and needs libstdc++.
        # Keep its runtime library in T3's closure and resolve it on each build.
        t3code = prev.t3code.overrideAttrs (old: {
          postBuild = (old.postBuild or "") + ''
            for program in "$out/bin/t3" "$out/bin/t3code-desktop"; do
              wrapProgram "$program" \
                --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [final.stdenv.cc.cc.lib]}
            done
          '';
        });
      })
    ];

    programs.nix-ld.enable = true;

    nix.settings.experimental-features = ["nix-command" "flakes"];
  };
}
