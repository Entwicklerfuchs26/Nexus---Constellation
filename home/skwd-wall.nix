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
in
{
  home.file =
    {
      ".config/skwd-wall/config.json".text =
        fixPaths (builtins.readFile ../dotfiles/skwd-wall/config.json);
    }
    // mkFilesFromDir ".config/skwd-wall/scripts" ../dotfiles/skwd-wall/scripts true
    // mkFilesFromDir ".config/skwd-wall/data/matugen/templates" ../dotfiles/skwd-wall/templates false;
}
