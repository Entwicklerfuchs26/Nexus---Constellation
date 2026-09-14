# skwd-wall Runtime-Config deklarativ statt über dotfiles/install.sh
# imperativ kopiert (siehe Vikunja: install.sh vergessen/falscher Pfad hat
# am 14.09.2026 beim Community-Install-Test die komplette GUI zerschossen).
# Ein `rebuild` reicht jetzt, kein separates Skript mehr nötig.
{ config, pkgs, lib, ... }:
let
  fixPaths = text:
    builtins.replaceStrings [ "/home/fuchs" ] [ config.home.homeDirectory ] text;

  mkFilesFromDir = destPrefix: srcDir: executable:
    let
      entries = builtins.readDir srcDir;
      names = builtins.attrNames
        (lib.filterAttrs (n: t: t == "regular" && n != ".gitkeep") entries);
    in
    lib.listToAttrs (map (name: {
      name = "${destPrefix}/${name}";
      value = {
        text = fixPaths (builtins.readFile (srcDir + "/${name}"));
      } // lib.optionalAttrs executable { executable = true; };
    }) names);

  configSeed = pkgs.writeText "skwd-wall-config.json.seed"
    (fixPaths (builtins.readFile ../dotfiles/skwd-wall/config.json));
in
{
  # config.json ist LAUFZEIT-Zustand (skwd speichert dort z.B. den zuletzt
  # gewählten Light/Dark-Modus zurück, siehe toggle-theme.sh) -- deshalb
  # NICHT als starrer home.file-Symlink (read-only, hat toggle-theme.sh am
  # 15.09.2026 mit "Read-only file system" blockiert), sondern nur einmalig
  # als beschreibbare Datei vorbelegt, falls sie noch nicht existiert.
  home.activation.skwdWallConfigSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="${config.home.homeDirectory}/.config/skwd-wall/config.json"
    if [ ! -e "$target" ]; then
      run mkdir -p "$(dirname "$target")"
      run cp ${configSeed} "$target"
      run chmod 644 "$target"
    fi
  '';

  home.file =
    mkFilesFromDir ".config/skwd-wall/scripts" ../dotfiles/skwd-wall/scripts true
    // mkFilesFromDir ".config/skwd-wall/data/matugen/templates" ../dotfiles/skwd-wall/templates false;
}
