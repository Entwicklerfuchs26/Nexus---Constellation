# Generischer Builder für die ArtCraft-Apps (storytold/*-craft).
# Nimmt die offiziellen Linux-x86_64-Release-Tarballs von GitHub (fertig gebaute
# Rust-Binaries, MIT/Apache-2.0), verifiziert per sha256 und wickelt sie so ein,
# dass wgpu/winit ihre Laufzeit-Bibliotheken (Vulkan, Wayland, X11) finden.
{ lib, stdenv, fetchurl, autoPatchelfHook, makeWrapper
, gcc-unwrapped, vulkan-loader, libxkbcommon, wayland, libGL
, libx11, libxcursor, libxi, libxrandr, libxcb, fontconfig, alsa-lib, openssl, zlib }:

{ pname, version, sha256, desc }:

stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/storytold/${pname}/releases/download/v${version}/${pname}-${version}-linux-x86_64.tar.gz";
    inherit sha256;
  };

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];
  buildInputs = [ gcc-unwrapped.lib alsa-lib ];
  sourceRoot = ".";

  # Die Binaries laden Grafik-Bibliotheken per dlopen -> nicht in NEEDED.
  runtimeLibs = [
    vulkan-loader libxkbcommon wayland libGL fontconfig alsa-lib openssl zlib
    libx11 libxcursor libxi libxrandr libxcb
  ];

  installPhase = ''
    runHook preInstall
    d=$(echo ${pname}-*-linux-x86_64)
    mkdir -p $out
    cp -r $d/bin $out/bin
    [ -d $d/share ] && cp -r $d/share $out/share
    for f in $out/bin/*; do
      wrapProgram "$f" --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
        vulkan-loader libxkbcommon wayland libGL fontconfig alsa-lib openssl zlib
        libx11 libxcursor libxi libxrandr libxcb
      ]}:/run/opengl-driver/lib"
    done
    runHook postInstall
  '';

  meta = {
    description = desc;
    homepage = "https://github.com/storytold/${pname}";
    license = [ lib.licenses.mit lib.licenses.asl20 ];
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
