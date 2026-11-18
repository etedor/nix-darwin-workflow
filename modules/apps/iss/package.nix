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
  version = "0-unstable-2026-11-05";

  src = fetchFromGitHub {
    owner = "jurplel";
    repo = "InstantSpaceSwitcher";
    rev = "2b883a995d1c81fbc6d75704372a6a0b546bb1ff";
    hash = "sha256-eDIGWzgqvWZg1lroNogiiMXYv0+rIcG9GpeB2DX+gfo=";
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
    mkdir -p "$appBundle/Contents/MacOS" "$appBundle/Contents/Resources" "$out/bin"

    install -m755 "$binPath/InstantSpaceSwitcher" "$appBundle/Contents/MacOS/"
    install -m755 "$binPath/ISSCli" "$appBundle/Contents/MacOS/"
    install -m644 Info.plist "$appBundle/Contents/Info.plist"
    install -m644 Resources/ISS.icns Resources/Assets.car "$appBundle/Contents/Resources/"

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
