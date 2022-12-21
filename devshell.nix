{ android-sdk, gradle, aapt2, jdk, open-keychain, devshell }:
let
  androidSdkRoot = "${android-sdk}/share/android-sdk";
  key = {
    name = "release";
    password = "xxxxxx";
    dn = "CN=None, OU=None, O=None, L=None, ST=None, C=US";
    store = "$GRADLE_USER_HOME/release.keystore";
  };
  src = "src";
  all = {
    name = "all";
    help = "copy source, generate release key, build and upload apk over usb";
  };
  gradleCmd = "gradle --no-daemon";
in
devshell.mkShell {
  name = "open-keychain";
  motd = ''
    Entered open-keychain android development environment.

    menu - list of commands
    ${all.name} - ${all.help}
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
      value = jdk.home;
    }
    {
      name = "GRADLE_USER_HOME";
      value = "./.gradle";
    }
  ];
  commands = [
    (all // {
      command = ''
        unpack
        cd ${src}
        configure
        build
        upload
      '';
    })
    {
      name = "unpack";
      help = "extract source to ${src} and set permissions";
      command = ''
        cp -r ${open-keychain} ${src}
        find ${src} -type d -exec chmod 755 '{}' ';'
      '';
    }
    {
      name = "configure";
      help = "set gradle properties and generate apk signing key";
      command = ''
        mkdir -p $GRADLE_USER_HOME
        test -f ${key.store} \
        || ${jdk}/bin/keytool \
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
        android.aapt2FromMavenOverride=${aapt2}/bin/aapt2
        EOF
      '';
    }
    {
      name = "build";
      help = "compile fdroid apks";
      command = "${gradleCmd} assembleFdroid";
    }
    {
      name = "upload";
      help = "install the release apk on any available android device";
      command =
        let
          adb = "${android-sdk}/bin/adb";
        in
        ''
          trap "${adb} kill-server" INT QUIT TERM EXIT
          echo "Waiting for device to upload APK to..."
          ${adb} wait-for-device
          ${gradleCmd} installFdroidRelease
        '';
    }
  ];
  packages = [
    # android-studio
    android-sdk
    gradle
    jdk
  ];
}

