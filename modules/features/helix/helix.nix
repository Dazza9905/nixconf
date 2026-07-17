{
  self,
  inputs,
  ...
}: {
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    configDir = pkgs.runCommand "helix-config" {} ''
      mkdir $out
      cp ${(pkgs.formats.toml {}).generate "config.toml" {
        theme = "noctalia";
        editor = {
          line-number = "relative";
          auto-format = true;
          auto-save = true;
          completion-trigger-len = 1;
          lsp = {
            display-messages = true;
            display-inlay-hints = true;
          };
          cursor-shape = {
            normal = "block";
            insert = "bar";
            select = "underline";
          };
          indent-guides = {
            render = true;
            character = "╎";
          };
          statusline = {
            left = ["mode" "spinner" "file-name" "file-modification-indicator"];
            right = ["diagnostics" "selections" "position" "file-encoding" "file-type"];
          };
        };
        keys.normal = {
          Ctrl-g = [":new" ":insert-output lazygit" ":buffer-close!" ":redraw"];
          y = "yank_to_clipboard";
          p = "paste_clipboard_after";
          P = "paste_clipboard_before";
          ">" = "indent";
          "<" = "unindent";
        };
        keys.select = {
          y = "yank_to_clipboard";
          p = "paste_clipboard_after";
          P = "paste_clipboard_before";
          ">" = "indent";
          "<" = "unindent";
        };
      }} $out/config.toml
      cp ${(pkgs.formats.toml {}).generate "languages.toml" {
        language = [
          {
            name = "nix";
            auto-format = true;
            formatter = {
              command = lib.getExe pkgs.alejandra;
              args = ["-"];
            };
            language-servers = ["nil"];
          }
          {
            name = "cpp";
            auto-format = true;
            formatter = {command = lib.getExe' pkgs.clang-tools "clang-format";};
            language-servers = ["clangd"];
          }
          {
            name = "c";
            auto-format = true;
            formatter = {command = lib.getExe' pkgs.clang-tools "clang-format";};
            language-servers = ["clangd"];
          }
          {
            name = "shader";
            auto-format = true;
            formatter = {command = lib.getExe' pkgs.clang-tools "clang-format";};
          }
        ];
        language-server = {
          nil.command = lib.getExe pkgs.nil;
          clangd = {
            command = lib.getExe' pkgs.clang-tools "clangd";
            args = ["--completion-style=detailed" "--header-insertion=never" "--background-index"];
          };
        };
      }} $out/languages.toml
    '';
  in {
    packages.myHelix = pkgs.writeShellApplication {
      name = "hx";
      runtimeInputs = [pkgs.evil-helix pkgs.nil pkgs.alejandra pkgs.clang-tools];
      text = ''
        cfg=$(mktemp -d)
        trap 'rm -rf "$cfg"' EXIT
        cp ${configDir}/config.toml "$cfg/"
        cp ${configDir}/languages.toml "$cfg/"
        if [ -d "$HOME/.config/helix/themes" ]; then
          cp -r "$HOME/.config/helix/themes" "$cfg/themes"
        fi
        HELIX_CONFIG_DIR="$cfg" exec hx "$@"
      '';
    };
  };
}
