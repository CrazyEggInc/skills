{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.writeShellApplication {
            name = "fmt";
            runtimeInputs = with pkgs; [
              findutils
              prettier
              shfmt
            ];
            text = ''
              prettier '**/*.md' --write
              find . -type f -name '*.sh' -exec shfmt -w {} +
            '';
          };

          checks = {
            markdown-format =
              pkgs.runCommand "markdown-format-check" { nativeBuildInputs = [ pkgs.prettier ]; }
                ''
                  cd ${./.}
                  prettier '**/*.md' --check
                  touch "$out"
                '';

            shell-format =
              pkgs.runCommand "shell-format-check"
                {
                  nativeBuildInputs = with pkgs; [
                    findutils
                    shfmt
                  ];
                }
                ''
                  cd ${./.}
                  find . -type f -name '*.sh' -exec shfmt -d {} +
                  touch "$out"
                '';

            shellcheck =
              pkgs.runCommand "shellcheck"
                {
                  nativeBuildInputs = with pkgs; [
                    findutils
                    shellcheck
                  ];
                }
                ''
                  cd ${./.}
                  find . -type f -name '*.sh' -exec shellcheck {} +
                  touch "$out"
                '';
          };

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              # skills deps
              jq
              ripgrep
              curl

              # dev deps
              git
              prettier
              shfmt
              shellcheck
            ];
          };
        };
    };
}
