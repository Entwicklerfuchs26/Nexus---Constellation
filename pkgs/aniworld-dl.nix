{ pkgs }:

let
  python = pkgs.python3.withPackages (ps: [ ps.requests ps.beautifulsoup4 ]);
  runtimeTools = with pkgs; [ aria2 yt-dlp ffmpeg wget ];
in
pkgs.writeShellScriptBin "aniworld-dl" ''
  export PATH="${pkgs.lib.makeBinPath runtimeTools}:$PATH"
  exec ${python}/bin/python3 ${./aniworld_dl.py} "$@"
''
