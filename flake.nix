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
      overlay = final: prev: {
        inherit (self.packages.${final.system}) android-sdk android-studio;
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
            self.overlay
          ];
        };
      in
      {
        packages = {
          android-sdk = android.sdk.${system} (sdkPkgs: with sdkPkgs; [
            # Useful packages for building and testing.
            build-tools-29-0-2
            build-tools-33-0-0 # for a compatible aapt2
            cmdline-tools-latest
            #emulator
            platform-tools
            platforms-android-29

            # Other useful packages for a development environment.
            # sources-android-30
            # system-images-android-30-google-apis-x86
            # system-images-android-30-google-apis-playstore-x86
          ]);

          # android-studio = pkgs.androidStudioPackages.stable;
          # android-studio = pkgs.androidStudioPackages.beta;
          # android-studio = pkgs.androidStudioPackages.preview;
          # android-studio = pkgs.androidStudioPackage.canary;
        };

        devShell = import ./devshell.nix { inherit pkgs open-keychain; };
      }
    );
}
