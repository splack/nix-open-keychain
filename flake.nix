{
  description = "open-keychain";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    devshell.url = "github:numtide/devshell";
    flake-utils.url = "github:numtide/flake-utils";
    android.url = "github:tadfisher/android-nixpkgs";
    open-keychain = {
      flake = false;
      url = "https://github.com/open-keychain/open-keychain";
      type = "git";
      ref = "refs/pull/2804/head";
      rev = "05722877a3f9211ab401bb35c5e8da8906b117fb";
      submodules = true;
    };
  };

  outputs = { self, nixpkgs, devshell, flake-utils, android, open-keychain }:
    {
      overlays.default = final: prev: {
        inherit (self.packages.${final.system}) android-sdk;
      };
    }
    //
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            devshell.overlay
            self.overlays.default
          ];
        };

        aapt2BuildToolsVersion = "33.0.0";

        android-sdk = android.sdk.${system} (sdkPkgs: with sdkPkgs; [
          build-tools-29-0-2
          build-tools-33-0-0 # for a compatible aapt2
          cmdline-tools-latest
          platform-tools
          platforms-android-29
        ]);
      in
      {
        devShell = import ./devshell.nix {
          inherit open-keychain android-sdk;
          inherit (pkgs) devshell;
          aapt2 = pkgs.stdenvNoCC.mkDerivation {
            name = "aapt2";
            buildCommand = ''
              dir="$out/bin"
              mkdir -p "$dir"
              cp "${android-sdk}/share/android-sdk/build-tools/${aapt2BuildToolsVersion}/aapt2" "$dir"
            '';
          };
          jdk = pkgs.openjdk11_headless;
          gradle = pkgs.gradle_6;
        };
      }
    );
}
