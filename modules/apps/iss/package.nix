{
  fetchFromGitHub,
  lib,
  makeWrapper,
  swift,
  swiftPackages,
  swiftpm,
  swiftpm2nix,
}:
let
  generated = swiftpm2nix.helpers ./nix;
in
swiftPackages.stdenv.mkDerivation {
  pname = "instant-space-switcher";
  version = "0-unstable-2026-04-10";

  src = fetchFromGitHub {
    owner = "jurplel";
    repo = "InstantSpaceSwitcher";
    rev = "afe511ab1c45ca5b3d2d173ab2a846cc23386ec3";
    hash = "sha256-HfL9FhAXTYZc7nWwwAoOW6l7UZdx7etXp3wAnzqyXTQ=";
  };

  nativeBuildInputs = [
    swift
    swiftpm
    makeWrapper
  ];

  configurePhase = generated.configure;

  installPhase = ''
    runHook preInstall

    binPath="$(swiftpmBinPath)"
    appBundle="$out/Applications/InstantSpaceSwitcher.app"
    mkdir -p "$appBundle/Contents/MacOS" "$out/bin"

    install -m755 "$binPath/InstantSpaceSwitcher" "$appBundle/Contents/MacOS/"
    install -m755 "$binPath/ISSCli" "$appBundle/Contents/MacOS/"
    install -m644 Info.plist "$appBundle/Contents/Info.plist"

    makeWrapper "$appBundle/Contents/MacOS/ISSCli" "$out/bin/ISSCli"

    runHook postInstall
  '';

  meta = {
    description = "Instant workspace switching on macOS without animations";
    homepage = "https://github.com/jurplel/InstantSpaceSwitcher";
    license = lib.licenses.mit;
    mainProgram = "ISSCli";
    platforms = lib.platforms.darwin;
  };
}
