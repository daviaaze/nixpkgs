{
  lib,
  stdenv,
  callPackage,
  fetchurl,
  appimageTools,
  commandLineArgs ? "",
  useVSCodeRipgrep ? stdenv.hostPlatform.isDarwin,
}:

let
  inherit (stdenv) hostPlatform;

  sources = {
    x86_64-linux = fetchurl {
      url = "https://downloads.cursor.com/production/53b99ce608cba35127ae3a050c1738a959750865/linux/x64/Cursor-1.0.0-x86_64.AppImage";
      hash = "sha256-HJiT3aDB66K2slcGJDC21+WhK/kv4KCKVZgupbfmLG0=";
    };
    aarch64-linux = fetchurl {
      url = "https://downloads.cursor.com/production/53b99ce608cba35127ae3a050c1738a959750865/linux/arm64/Cursor-1.0.0-aarch64.AppImage";
      hash = "sha256-/F+OUD+sjnIt2ishusi7F/W1kK/n7hwL7Bz1cO3u+x4=";
    };
    x86_64-darwin = fetchurl {
      url = "https://downloads.cursor.com/production/53b99ce608cba35127ae3a050c1738a959750865/darwin/x64/Cursor-darwin-x64.dmg";
      hash = "sha256-7JTgauy+vdoaPOtbYjhSCR+ZtVwzRYKHVelpnvS5oKw=";
    };
    aarch64-darwin = fetchurl {
      url = "https://downloads.cursor.com/production/53b99ce608cba35127ae3a050c1738a959750865/darwin/arm64/Cursor-darwin-arm64.dmg";
      hash = "sha256-kbSN4+ozVGVAGLqEuaDnWBNfzmFHYdAvbOsCb/KTpe8=";
    };
  };

  source = sources.${hostPlatform.system};
in
(callPackage ./generic.nix rec {
  inherit commandLineArgs useVSCodeRipgrep;

  version = "1.0.0";
  pname = "cursor";

  executableName = "cursor";
  libraryName = "cursor";
  longName = "Cursor";
  shortName = "cursor";

  src =
    if hostPlatform.isLinux then
      appimageTools.extract {
        inherit pname version;
        src = source;
      }
    else
      source;

  sourceRoot = if hostPlatform.isLinux then "${pname}-${version}-extracted/usr/share/cursor" else ".";

  tests = { };

  updateScript = ./update-cursor.sh;

  # Editing the `cursor` binary within the app bundle causes the bundle's signature
  # to be invalidated, which prevents launching starting with macOS Ventura, because VS Code is notarized.
  # See https://eclecticlight.co/2022/06/17/app-security-changes-coming-in-ventura/ for more information.
  dontFixup = stdenv.hostPlatform.isDarwin;

  # Cursor has no wrapper script.
  patchVSCodePath = false;

  meta = {
    description = "AI-powered code editor built on vscode";
    homepage = "https://cursor.com";
    changelog = "https://cursor.com/changelog";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [
      aspauldingcode
      prince213
    ];
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    mainProgram = "cursor";
  };
}).overrideAttrs
  (oldAttrs: {
    preInstall =
      (oldAttrs.preInstall or "")
      + lib.optionalString hostPlatform.isLinux ''
        mkdir -p bin
        ln -s ../cursor bin/cursor
      '';

    passthru = (oldAttrs.passthru or { }) // {
      inherit sources;
    };
  })
