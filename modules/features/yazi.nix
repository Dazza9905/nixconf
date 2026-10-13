{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.yazi = {
    pkgs,
    lib,
    ...
  }: {
    programs.yazi = {
      enable = true;
      settings.yazi = {
        opener.image = [{
          run = "${lib.getExe pkgs.imv} -- %s";
          orphan = true;
          desc = "View image";
          for = "linux";
        }];
        opener.pdf = [{
          run = "${lib.getExe pkgs.sioyek} -- %s";
          orphan = true;
          desc = "Sioyek";
          for = "linux";
        }];
        opener.pdf-edit = [{
          run = "${lib.getExe pkgs.xournalpp} %s";
          orphan = true;
          desc = "Xournal++";
          for = "linux";
        }];
        open.prepend_rules = [
          {
            mime = "application/pdf";
            use = ["pdf" "pdf-edit" "open"];
          }
          {
            url = "*.pdf";
            use = ["pdf" "pdf-edit" "open"];
          }
          {
            mime = "image/*";
            use = "image";
          }
        ];
      };
      settings.keymap.mgr.prepend_keymap = [
        {
          on = "<Enter>";
          run = "open";
          desc = "Open with default app";
        }
        {
          on = "<S-Enter>";
          run = "open --interactive";
          desc = "Choose an app";
        }
        {
          on = "O";
          run = "open --interactive";
          desc = "Choose an app";
        }
      ];
    };

    # Prefer the configured system wrapper over a user-profile installation.
    environment.shellAliases.yazi = "/run/current-system/sw/bin/yazi";

    # Qt discovers these system-wide defaults through XDG_CONFIG_DIRS.
    environment.etc."xdg/sioyek/keys_user.config".text = ''
      move_left h
      move_down j
      move_up k
      move_right l
      previous_page H
      next_page J
      previous_page K
      next_page L
      goto_beginning gg
      goto_end G
    '';
    environment.etc."xdg/sioyek/prefs_user.config".text = ''
      startup_commands toggle_smooth_scroll_mode
      smooth_scroll_speed 3
      smooth_scroll_drag 3000
      check_for_updates_on_startup 0
      # Sioyek automatically reloads PDFs when the file changes.
    '';

    environment.systemPackages = [pkgs.imv pkgs.sioyek pkgs.xournalpp];
  };
}
