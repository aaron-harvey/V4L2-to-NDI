{ lib, stdenv, pkgs, avahi, obs-studio-plugins }:

let
  ndiPlatform = "x86_64-linux-gnu";
in

stdenv.mkDerivation rec {
  pname = "ndi";
  version = "5.6.0";




  majorVersion = builtins.head (builtins.splitVersion version);
  installerName = "Install_NDI_SDK_v${majorVersion}_Linux";


  src = pkgs.fetchurl {
    url = "https://downloads.ndi.tv/SDK/NDI_SDK_Linux/Install_NDI_SDK_v5_Linux.tar.gz";
    # hash = "sha256-T/S5LyxfQtI0qn0ULi3n6bBFxytGrVFJpFnUjv2SGN4=";
    hash = "sha256:4ff4b92f2c5f42d234aa7d142e2de7e9b045c72b46ad5149a459d48efd9218de";


  };


  buildInputs = [ avahi ];

  unpackPhase = ''
    unpackFile $src
    echo y | ./${installerName}.sh
    sourceRoot="NDI SDK for Linux";
  '';




  installPhase = ''
    mkdir $out
    mv bin/${ndiPlatform} $out/bin
    for i in $out/bin/*; do
      if [ -L "$i" ]; then continue; fi
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$i"
    done
    patchelf --set-rpath "${avahi}/lib:${stdenv.cc.libc}/lib" $out/bin/ndi-record
    mv lib/${ndiPlatform} $out/lib
    for i in $out/lib/*; do
      if [ -L "$i" ]; then continue; fi
      patchelf --set-rpath "${avahi}/lib:${stdenv.cc.libc}/lib" "$i"
    done
    mv include examples $out/
    mkdir -p $out/share/doc/${pname}-${version}
    mv licenses $out/share/doc/${pname}-${version}/licenses
    mv documentation/* $out/share/doc/${pname}-${version}/
  '';


  # Stripping breaks ndi-record.
  dontStrip = true;

  passthru.tests = {
    inherit (obs-studio-plugins) obs-ndi;
  };
  passthru.updateScript = ./update.py;

  meta = with lib; {
    homepage = "https://ndi.tv/sdk/";
    description = "NDI Software Developer Kit";
    platforms = [ "x86_64-linux" ];
    hydraPlatforms = [ ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
  };
}
