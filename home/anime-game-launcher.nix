{ config, ... }:

{
  # Die vorhandene Genshin-Impact-Installation liegt auf der Spieleplatte
  # (/mnt/games/AnimeGameLauncher, urspruenglich die Flatpak-Variante). Der
  # native, deklarativ installierte An Anime Game Launcher erwartet seine
  # Daten unter ~/.local/share/anime-game-launcher. Statt alles umzukopieren
  # zeigen wir per Out-of-Store-Symlink dorthin -- so bleiben Spiel, Wine-
  # Prefix, Runner, DXVK und config.json erhalten und der Launcher kann
  # weiter frei hineinschreiben. Die Pfade in der config.json wurden einmalig
  # von den Flatpak- auf diese nativen Pfade umgebogen.
  home.file.".local/share/anime-game-launcher".source =
    config.lib.file.mkOutOfStoreSymlink
      "/mnt/games/AnimeGameLauncher/data/anime-game-launcher";
}
