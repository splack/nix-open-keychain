{ pkgs, open-keychain }:
with pkgs;
let
  buildToolsVersion = "33.0.0";
  androidSdkRoot = "${android-sdk}/share/android-sdk";
  key = {
    name = "release";
    password = "xxxxxx";
    dn = "CN=None, OU=None, O=None, L=None, ST=None, C=US";
    store = "$GRADLE_USER_HOME/release.keystore";
  };
  src = "src";
in
# Configure your development environment.
#
# Documentation: https://github.com/numtide/devshell
devshell.mkShell {
  name = "open-keychain";
  motd = ''
    Entered the Android app development environment.

    menu - list of commands
  '';
  env = [
    {
      name = "ANDROID_HOME";
      value = androidSdkRoot;
    }
    {
      name = "ANDROID_SDK_ROOT";
      value = androidSdkRoot;
    }
    {
      name = "JAVA_HOME";
      value = jdk11.home;
    }
    {
      name = "GRADLE_USER_HOME";
      value = "./.gradle";
    }
  ];
  commands = [
    {
      name = "all";
      help = "copy source, generate release key, build and upload apk over usb";
      command = ''
        unpack
        cd ${src}
        configure
        build
        upload
      '';
    }
    {
      name = "unpack";
      command = ''
        cp -r ${open-keychain} ${src}
        find ${src} -type d -exec chmod 755 '{}' ';'
      '';
    }
    {
      name = "configure";
      command = ''
        mkdir -p $GRADLE_USER_HOME
        test -f ${key.store} \
        || keytool \
          -genkey \
          -keystore ${key.store} \
          -alias ${key.name} \
          -keyalg RSA \
          -keysize 2048 \
          -validity 1000000 \
          -dname '${key.dn}' \
          -storepass ${key.password}
        test -f $GRADLE_USER_HOME/gradle.properties \
        || cat <<EOF >$GRADLE_USER_HOME/gradle.properties
        signingStoreLocation=../${key.store}
        signingStorePassword=${key.password}
        signingKeyAlias=${key.name}
        signingKeyPassword=${key.password}
        android.aapt2FromMavenOverride=${androidSdkRoot}/build-tools/${buildToolsVersion}/aapt2
        EOF
      '';
    }
    {
      name = "build";
      command = "gradle assembleFdroid";
    }
    {
      name = "upload";
      command = "adb install OpenKeychain/build/outputs/apk/fdroid/release/OpenKeychain-fdroid-release.apk";
    }
  ];
  packages = [
    # android-studio
    android-sdk
    gradle_6
    jdk11
  ];
}

