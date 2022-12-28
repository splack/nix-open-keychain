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
      ref = "refs/heads/master";
      rev = "c1861535bc73d42cc572a5c9f82213c7d6260045";
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

        android-sdk = android.sdk.${system} (sdkPkgs: with sdkPkgs; [
          build-tools-30-0-2
          cmdline-tools-latest
          platform-tools
          platforms-android-33
        ]);
      in
      {
        devShell = import ./devshell.nix {
          inherit open-keychain android-sdk;
          inherit (pkgs) devshell;
          aapt2 = pkgs.callPackage "${android}/pkgs/aapt2" {};
          jdk = pkgs.openjdk11_headless;
          gradle = pkgs.gradle_6;
        };
      }
    );
}
