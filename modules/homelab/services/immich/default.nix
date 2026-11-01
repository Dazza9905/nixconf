{
  config,
  lib,
  pkgs,
  ...
}:
let
  homelab = config.homelab;
  cfg = homelab.services.immich;
in
{
# =======================================================
# IMPORTS
# =======================================================
  imports = [ ./backup.nix ];

# =======================================================
# OPTIONS
# =======================================================
  options.homelab.services.immich = {
    enable = lib.mkEnableOption "Enable Immich";
    mediaDir = lib.mkOption {
      type = lib.types.str;
      default = "${homelab.mount}/immich-app/data";
    };
    ipp = lib.mkEnableOption "Enable Immich Public Proxy";

  };
# =======================================================
# CONFIG
# =======================================================
  config = lib.mkIf cfg.enable {

    services.immich = {
      enable = true;
      host = "0.0.0.0";
      group = homelab.group;
      port = 2283;
      mediaLocation = cfg.mediaDir;

    };
    services.immich-public-proxy = {
      enable = cfg.ipp;
      immichUrl = "http://192.168.100.21:2283";
      openFirewall = true;
      settings = {
        ipp = {
          maxDownloadQuality = "original";
          downloadedFilename = 0;
          allowDownload = 1;
          downloadFromImmichConcurrencyLimit = 2;

          gallery = {
            singleImage = false;
            singleVideo = false;
            singleItemAutoOpen = true;
            showTitle = true;
            showDescription = true;
            groupByDate = true;
          };

          lightbox = {
            showDownload = false;
            showArrows = true;
            mobileArrows = true;

            options = {
              autoPlayVideos = true;
              bgOpacity = 0.85;
            };
          };

          showMetadata = {
            description = {
              caption = false;
              sidebar = true;
            };

            exif = {
              dateTimeOriginal = true;
              make = true;
              model = true;
              lensModel = true;
              exposureTime = true;
              iso = true;
              fNumber = true;
              focalLength = true;
            };

            location = {
              city = true;
              state = true;
              country = true;
            };
          };
        };
      };
    };

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 2283 ];
    };

  };

}
