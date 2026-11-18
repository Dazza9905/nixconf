{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.remoteDesktop = {
    pkgs,
    lib,
    config,
    username,
    ...
  }: {
# =======================================================
# OPTIONS
# =======================================================
    options.settings = {
      enable = lib.mkEnableOption "get acces to set of settings";
      
      remoteDesktop = {
        server = lib.mkEnableOption "turn on sunshine";
        client = lib.mkEnableOption "turn on moonlight-qt";
      };
    };
# =======================================================
# CONFIG
# =======================================================
    config = lib.mkMerge [
      (lib.mkIf config.settings.remoteDesktop.server {
        services.sunshine = {
          enable = true;
          autoStart = true;
          capSysAdmin = true;
          openFirewall = true;
          package = pkgs.sunshine.override {
            cudaSupport = true;
            cudaPackages = pkgs.cudaPackages;
          };
        };
      })
      (lib.mkIf config.settings.remoteDesktop.client {
        users.users.${username} = {
          extraGroups = ["uinput" "video" "render"];
          packages = with pkgs; [
            moonlight-qt
          ];
        };
        hardware.uinput.enable = true;
      })
    ];
  };
}
