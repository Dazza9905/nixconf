{inputs, ...}: {
  perSystem = {pkgs, lib, ...}: {
    packages.myNoctalia = inputs.wrapper-modules.lib.evalPackage {
      imports = [inputs.wrapper-modules.lib.modules.default];
      inherit pkgs;
      package = pkgs.noctalia;
      env.NOCTALIA_PLUGIN_NIRI = lib.getExe pkgs.niri;
      env.NOCTALIA_CONFIG_HOME = pkgs.writeTextDir
        "noctalia/config.toml"
        (builtins.readFile ./config.toml + ''

          [[plugins.source]]
          name = "official"
          kind = "git"
          location = "https://github.com/noctalia-dev/official-plugins"
          enabled = true

          [[plugins.source]]
          name = "community"
          kind = "git"
          location = "https://github.com/noctalia-dev/community-plugins"
          enabled = true

          [[plugins.source]]
          name = "dazza-local"
          kind = "path"
          location = "/home/dazza/.nixconf/modules/features/noctalia/plugins"
          enabled = true
        '');
    };
  };
}
