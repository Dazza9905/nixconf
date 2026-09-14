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
      (plasticity.overrideAttrs (old: {
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
