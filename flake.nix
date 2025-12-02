{
  description = "Syncwagon Android - Browse-first Syncthing mobile client";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs";
    android-nixpkgs.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, git-hooks, android-nixpkgs }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.git-hooks.flakeModule
      ];

      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          # Android SDK configuration using android-nixpkgs
          android-sdk = android-nixpkgs.sdk.${system} (sdkPkgs: with sdkPkgs; [
            cmdline-tools-latest
            build-tools-34-0-0
            platform-tools
            platforms-android-34
            platforms-android-33
            ndk-26-1-10909125
          ]);
        in
        {
        # Pre-commit hooks configuration
        pre-commit.settings = {
          hooks = {
            # Standard checks
            trailing-whitespace = {
              enable = true;
              name = "trailing-whitespace";
            };
            end-of-file-fixer = {
              enable = true;
              name = "end-of-file-fixer";
            };
            check-yaml = {
              enable = true;
              name = "check-yaml";
            };
            check-merge-conflict = {
              enable = true;
              name = "check-merge-conflict";
            };

            # Go formatting and linting
            gofmt = {
              enable = true;
              name = "gofmt";
            };
            goimports = {
              enable = true;
              name = "goimports";
            };
            govet = {
              enable = true;
              name = "go vet";
            };

            # Kotlin formatting
            ktlint = {
              enable = true;
              name = "ktlint";
              entry = "${pkgs.ktlint}/bin/ktlint --format";
              files = "\\.kt$";
            };
          };
        };
        devShells.default = pkgs.mkShell {
          inputsFrom = [
            config.pre-commit.devShell
          ];

          buildInputs = with pkgs; [
            # Go toolchain
            go
            gomobile

            # Java Development Kit
            jdk17

            # Android SDK and tools
            android-sdk
            gradle

            # Formatters (used by pre-commit hooks)
            gofumpt
            gotools # includes goimports
            ktlint

            # Build tools
            git
            gnumake

            # Helpful utilities
            ripgrep
            fd
          ];

          shellHook = ''
            # Set Android SDK environment variables
            export ANDROID_HOME="${android-sdk}/share/android-sdk"
            export ANDROID_SDK_ROOT="$ANDROID_HOME"
            export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH"

            # Set up Java
            export JAVA_HOME="${pkgs.jdk17}/lib/openjdk"

            # Set up Go
            export GOPATH="$PWD/.go"
            export GOCACHE="$PWD/.go/cache"
            export PATH="$GOPATH/bin:$PATH"

            # Initialize gomobile if not already done
            if [ ! -d "$GOPATH/pkg/gomobile" ]; then
              echo "Initializing gomobile..."
              gomobile init || true
            fi

            echo "Syncwagon development environment loaded!"
            echo "  Go:           $(go version)"
            echo "  Java:         $(java -version 2>&1 | head -n 1)"
            echo "  Android SDK:  $ANDROID_HOME"
            echo "  Gradle:       $(gradle --version | grep Gradle)"
            echo ""
            echo "Pre-commit hooks are installed automatically via git-hooks.nix"
          '';
        };
      };
    };
}
