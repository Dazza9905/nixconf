{
  self,
  inputs,
  ...
}: {
  perSystem = {
    pkgs,
    lib,
    ...
  }: {
    packages.myHelix = inputs.wrapper-modules.wrappers.helix.wrap {
      inherit pkgs;
      package = pkgs.evil-helix;

      settings = {
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
      };

      languages = {
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
        ];
        language-server = {
          nil.command = lib.getExe pkgs.nil;
          clangd.command = lib.getExe' pkgs.clang-tools "clangd";
        };
      };
    };
  };
}
