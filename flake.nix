{
  description = "BOS Build System";
  nixConfig.bash-prompt-prefix = "(bos) ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixlib.url = "git+ssh://git@gitlab.ii.zone/bos/nixlib";
  };

  outputs = { self, nixpkgs, flake-utils, ... } @ inputs:
    flake-utils.lib.eachSystem [ "x86_64-linux" ]
      (localSystem:
        let
          pkgs = import nixpkgs {
            inherit localSystem;
          };

          mkApp = drv: { type = "app"; program = pkgs.lib.getExe drv; };

        in
        {
          formatter = inputs.nixlib.mkFormatter.${localSystem} {
            nix = true;
          };

          apps = pkgs.lib.mapAttrs (_: mkApp) {
            bootstrap = pkgs.writeShellApplication {
              name = "bootstrap";
              runtimeInputs = with pkgs; [ coreutils openssh_gssapi git ];
              runtimeEnv = {
                PATH = null;
              };
              excludeShellChecks = [ "SC2123" ];
              text = builtins.readFile ./scripts/00_bootstrap.sh;
            };

            configure = pkgs.writeShellApplication {
              name = "configure";
              runtimeInputs = with pkgs; [ coreutils nix gnused ];
              runtimeEnv = {
                PATH = null;
              };
              excludeShellChecks = [ "SC2123" ];
              text = builtins.readFile ./scripts/01_configure.sh;
            };

            make = pkgs.writeShellApplication {
              name = "make";
              runtimeInputs = with pkgs; [ coreutils nix ];
              runtimeEnv = {
                PATH = null;
              };
              excludeShellChecks = [ "SC2123" ];
              text = builtins.readFile ./scripts/02_make.sh;
            };
          };

        });
}
