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
      url = "https://downloads.cursor.com/production/96e5b01ca25f8fbd4c4c10bc69b15f6228c80771/linux/x64/Cursor-0.50.5-x86_64.AppImage";
      hash = "sha256-DUWIgQYD3Wj6hF7NBb00OGRynKmXcFldWFUA6W8CZeM=";
    };
    aarch64-linux = fetchurl {
      url = "https://downloads.cursor.com/production/96e5b01ca25f8fbd4c4c10bc69b15f6228c80771/linux/arm64/Cursor-0.50.5-aarch64.AppImage";
      hash = "sha256-51zTYg4A+4ZUbGZ6/Qp3d5aL8IafewGOUYbXWGG8ILY=";
    };
    x86_64-darwin = fetchurl {
      url = "https://downloads.cursor.com/production/96e5b01ca25f8fbd4c4c10bc69b15f6228c80771/darwin/x64/Cursor-darwin-x64.dmg";
      hash = "sha256-C2+z3WXi3Ma3PzlU8BrcuJFGMx8YosNdxuSqR5tJdBE=";
    };
    aarch64-darwin = fetchurl {
      url = "https://downloads.cursor.com/production/96e5b01ca25f8fbd4c4c10bc69b15f6228c80771/darwin/arm64/Cursor-darwin-arm64.dmg";
      hash = "sha256-Gz+aYDaDMDx46R7HA8u5vZwkXx9q//uu4hNyyRmrq9s=";
    };
  };

  source = sources.${hostPlatform.system};
in
(callPackage ./generic.nix rec {
  inherit commandLineArgs useVSCodeRipgrep;

  version = "0.50.5";
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
