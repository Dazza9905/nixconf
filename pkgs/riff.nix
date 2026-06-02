{ pkgs, inputs }:

pkgs.stdenv.mkDerivation {
  pname = "riff";
  version = "unstable-${inputs.riff-src.shortRev}";
  src = inputs.riff-src;

  cargoDeps = pkgs.rustPlatform.importCargoLock {
    lockFile = "${inputs.riff-src}/Cargo.lock";
  };

  nativeBuildInputs = with pkgs; [
    meson ninja pkg-config rustc cargo
    wrapGAppsHook4 blueprint-compiler gettext python3
    rustPlatform.cargoSetupHook
  ];

  buildInputs = with pkgs; [
    glib gtk4 libadwaita openssl dbus
    alsa-lib libpulseaudio libsecret
  ];

  mesonFlags = [ "-Dbuildtype=release" "-Doffline=false" ];
}
