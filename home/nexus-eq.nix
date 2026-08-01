{ config, pkgs, lib, ... }:
{
  home.file.".local/bin/eq_apply.py" = {
    source = ./files/nexus-eq/eq_apply.py;
    executable = true;
  };

  # Startzustand (flach, alle Baender 0dB) als ECHTE, beschreibbare Datei
  # seeden — kein home.file-Symlink, sonst kann eq_apply.py sie beim
  # Anwenden eines Reglers/Presets nicht ueberschreiben (read-only Nix-Store).
  # Nur beim ersten Mal anlegen, spaetere Anwendungen bleiben erhalten.
  home.activation.nexusEqDefault = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.config/pipewire/pipewire.conf.d/99-equalizer.conf"
    if [ ! -e "$target" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$target")"
      $DRY_RUN_CMD cp ${./files/nexus-eq/99-equalizer-default.conf} "$target"
    fi
  '';
}
