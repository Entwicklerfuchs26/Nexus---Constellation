# AniWorld Downloader – Web-Variante (Browser, gleiche Optik wie aniworld-gui).
# Teilt sich den externen Quellordner mit aniworld-gui.nix.
{ pkgs, aniworld-gui-src }:

let
  python = pkgs.python3.withPackages (ps: [ ps.requests ps.beautifulsoup4 ]);
  runtimeTools = with pkgs; [ aria2 yt-dlp ffmpeg wget ];
in
pkgs.writeShellScriptBin "aniworld-web" ''
  export PATH="${pkgs.lib.makeBinPath runtimeTools}:$PATH"
  exec ${python}/bin/python3 ${aniworld-gui-src}/server.py "$@"
''
