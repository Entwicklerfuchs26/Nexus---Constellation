# Claude Desktop (offizielle Linux-Beta) systemweit installieren.
#
# Features: Claude Code im Desktop (parallele Sessions, Seitenleiste zur
# Session-Verwaltung, Drag-and-Drop-Workspace, integriertes Terminal +
# Datei-Editor) sowie der eingebaute Browser-Panel (Strg+Shift+B): Element
# antippen -> Kontext für den nächsten Prompt, Screenshots/Elemente annotieren.
# Nicht auf Linux: Computer Use (gebündeltes virtiofsd/qemu ungenutzt) und
# Dictation -- beides bewusst egal.
#
# allowUnfree ist global aktiv (modules/core/base.nix), daher kein Predicate.
# Das Paket-Rezept liegt in pkgs/claude-desktop.nix (offizielles .deb -> Nix).
{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.callPackage ../../pkgs/claude-desktop.nix { })
  ];
}
