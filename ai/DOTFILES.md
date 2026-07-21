# Theming-System (matugen / skwd-wall)

skwd-wall ist der Wallpaper-Daemon (NixOS-Modul via Flake-Input `skwd-wall`). Bei Wallpaper-Wechsel
konvertiert `dotfiles/skwd-wall/scripts/matugen-apply.sh` das aktuelle Bild und ruft `matugen` mit
`--source-color-index 0` auf, um eine Material-You-Farbpalette zu extrahieren. matugen rendert daraus
alle in `dotfiles/matugen/config.toml` gelisteten `.templ`-Dateien zu fertigen Configs und schreibt sie
direkt in `~/.config/<app>/...`. Parallel liest skwd-wall seine eigenen Templates aus
`dotfiles/skwd-wall/templates/` und rendert sie in `~/.config/skwd-wall/data/matugen/templates/`.
Nach dem Rendern stoßen die `reload-*.sh`-Skripte in `dotfiles/skwd-wall/scripts/` betroffene Programme
zum Neuladen an (Waybar-Signal, KDE-Farbschema, Dock-Neustart, Spicetify, Niri-Config-Patch). Zusätzlich
verteilen `apply-borders.sh` (Hyprland-Ränder), `papirus-color.sh` (Icon-Theme-Farbe), `openrgb-apply.sh`
(RGB-Hardware) und `hyperion-sync.sh` (Ambilight) die Primärfarbe weiter an Hardware/Desktop-Elemente.
Alle Skripte lesen die Farben zentral aus `~/.config/matugen/colors.sh`. Das Setup wird einmalig über
`dotfiles/install.sh` nach `~/.config/{matugen,skwd-wall}/` kopiert — es ist **nicht** Home-Manager-verwaltet.

## Vom Daemon zur Laufzeit geschriebene Dateien (nicht HM-managed)

- `~/.config/matugen/colors.sh` — zentrale Farbvariablen (`MATUGEN_PRIMARY`, `MATUGEN_SURFACE`, ...)
- `~/.config/waybar/style.css`, `~/.config/wlogout/style.css`, `~/.config/nwg-dock-hyprland/style.css.templ` → `style.css`
- `~/.config/kdeglobals`, `~/.config/hypr/hyprlock.conf`
- `~/.config/skwd-wall/data/matugen/templates/*` (gerenderte Varianten aller Dateien aus `dotfiles/skwd-wall/templates/`, z. B. `waybar.css`, `kitty.conf`, `ghostty.conf`, `niri-colors.kdl`, `spicetify.css`)
- `$HOME/.local/share/color-schemes/SkwdMatugenAlt.colors` (von `reload-kde.sh`)
- `$XDG_CACHE_HOME/skwd-wall/niri-primary-color`

## Template-Pfade

- `dotfiles/matugen/config.toml` — Mapping input → output für matugen-Templates
- `dotfiles/matugen/*.templ` — matugen-Templates (colors.sh, kdeglobals, hyprlock.conf)
- `dotfiles/skwd-wall/templates/*` — skwd-wall-eigene Templates (21 Dateien, je Zielapp eine)
- `dotfiles/skwd-wall/scripts/*` — Reload-/Sync-Skripte, laufen nach jedem Rendering
