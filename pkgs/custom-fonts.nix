# Persönliche Font-Sammlung (schriften.zip), 2026-08-16 installiert.
# Quelle liegt bewusst AUSSERHALB des Git-Repos unter /etc/nixos/local-fonts
# (teils kommerzielle Fonts, dürfen nicht ins öffentliche GitHub-Repo) und
# wird als eigener Flake-Input "custom-fonts" (path:) eingebunden, sonst
# verbietet die pure Evaluation den absoluten Pfad.
{ stdenvNoCC, custom-fonts }:

stdenvNoCC.mkDerivation {
  pname = "custom-fonts";
  version = "1";

  src = custom-fonts;
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/share/fonts/opentype/custom $out/share/fonts/truetype/custom
    find $src -maxdepth 1 -iname '*.otf' -exec cp {} $out/share/fonts/opentype/custom/ \;
    find $src -maxdepth 1 -iname '*.ttf' -exec cp {} $out/share/fonts/truetype/custom/ \;
  '';
}
