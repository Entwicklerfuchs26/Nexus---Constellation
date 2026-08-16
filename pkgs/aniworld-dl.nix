# AniDL-CLI (für AniO). Quelle liegt bewusst AUSSERHALB des Git-Repos unter
# /etc/nixos/local-scripts/aniworld-dl (Scraper-Code, nicht für das öffentliche
# GitHub-Repo geeignet) und wird als Flake-Input "aniworld-dl-src" (path:)
# eingebunden, analog zu custom-fonts.nix.
{ pkgs, aniworld-dl-src }:

let
  python = pkgs.python3.withPackages (ps: [ ps.requests ps.beautifulsoup4 ]);
  runtimeTools = with pkgs; [ aria2 yt-dlp ffmpeg wget ];
in
pkgs.writeShellScriptBin "aniworld-dl" ''
  export PATH="${pkgs.lib.makeBinPath runtimeTools}:$PATH"
  exec ${python}/bin/python3 ${aniworld-dl-src}/aniworld_dl.py "$@"
''
