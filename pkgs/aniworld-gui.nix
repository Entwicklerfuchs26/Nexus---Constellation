# AniWorld Downloader GUI — eigenständige Tkinter-Fenster-App.
# Quelle liegt bewusst AUSSERHALB des Git-Repos unter /etc/nixos/aniworld-gui
# (Scraper-Code, nicht für das öffentliche GitHub-Repo geeignet) und wird als
# Flake-Input "aniworld-gui-src" (path:) eingebunden. Web-Variante siehe
# aniworld-web.nix.
{ pkgs, aniworld-gui-src }:

let
  python = pkgs.python3.withPackages (ps: [ ps.requests ps.beautifulsoup4 ps.tkinter ]);
  runtimeTools = with pkgs; [ aria2 yt-dlp ffmpeg wget ];
in
pkgs.writeShellScriptBin "aniworld-gui" ''
  export PATH="${pkgs.lib.makeBinPath runtimeTools}:$PATH"
  exec ${python}/bin/python3 ${aniworld-gui-src}/gui.py "$@"
''
