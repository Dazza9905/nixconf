{ self,
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
      (plasticity.overrideAttrs (old: rec {
        # version = "26.2.1"; # Set the release you want

        # src = pkgs.fetchurl {
        #   url = "https://github.com/nkallen/plasticity/releases/download/v${version}/Plasticity-${version}-1.x86_64.rpm";
        #   hash = "sha256-h07lm3DvXoc9FX9HSsJrGFYD+icBMgTSGNZp7MHw8fk=";
        # };

        nativeBuildInputs = (old.nativeBuildInputs or []) ++ [makeWrapper];
        postFixup =
          (old.postFixup or "")
          + ''
            wrapProgram "$out/bin/Plasticity" \
              --add-flags "--force-device-scale-factor=1.5"
          '';
      }))
      (lycheeslicer.overrideAttrs (old: {
        postInstall =
          (old.postInstall or "")
          + ''
            substituteInPlace "$out/share/applications/Lychee Slicer.desktop" \
              --replace "MimeType=model/stl" "MimeType=model/stl;x-scheme-handler/lycheeslicer"
          '';
      }))
    ];
  };
}
