#!/usr/bin/env bash
set -e

# Läuft NACH `sudo nixos-rebuild switch` (siehe INSTALL.md) -- kümmert sich
# nur um die skwd-wall/matugen-Runtime-Dateien, die (noch) nicht deklarativ
# über Home-Manager laufen, sondern zur Laufzeit im Home-Ordner liegen
# müssen.

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "==> [1/2] skwd-wall einrichten..."
mkdir -p ~/.config/skwd-wall/data/matugen/templates
mkdir -p ~/.config/skwd-wall/scripts
cp "$DOTFILES/skwd-wall/config.json" ~/.config/skwd-wall/
cp "$DOTFILES/skwd-wall/scripts/"* ~/.config/skwd-wall/scripts/
chmod +x ~/.config/skwd-wall/scripts/*.sh
cp "$DOTFILES/skwd-wall/templates/"* ~/.config/skwd-wall/data/matugen/templates/

echo "==> [2/2] matugen-Hilfsskripte einrichten..."
mkdir -p ~/.config/matugen
cp "$DOTFILES/matugen/"*.sh ~/.config/matugen/ 2>/dev/null || true
chmod +x ~/.config/matugen/*.sh 2>/dev/null || true

echo "==> Fertig! Bitte neu einloggen (oder Hyprland-Session neu starten)."
