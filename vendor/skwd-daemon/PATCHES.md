# Lokale Patches

Basis: `github:liixini/skwd-daemon` @ `36f165a68611dfc55f1878ddd34491cdb6e22a44`

## Zombie-Reap-Fix (2026-07-25)

`ManagedProcess::is_running()` (`crates/daemon/src/server/process.rs`) reaped
beendete Kindprozesse (wall-ui/host/music) nur, wenn danach nochmal
`launch()`/`toggle()`/`kill()` auf demselben `ManagedProcess` aufgerufen wurde.
Stürzte ein Prozess ohne folgenden Toggle ab, blieb er als `<defunct>`-Kind von
`skwd-daemon` hängen.

Fix in `crates/daemon/src/server/connection.rs::run()`: periodischer Task
(alle 5s), der `is_running()` auf `ui`, `host` und `music_proc` aufruft und so
verwaiste Kindprozesse zuverlässig reaped.

Beim nächsten Upstream-Update (`nix flake lock --update-input skwd-daemon`
gegen eine neue GitHub-Rev) muss dieser Patch erneut manuell übernommen werden,
falls das Upstream-Projekt das Problem nicht selbst behoben hat.

## WE-Removed-DB-Leak-Fix (2026-07-26)

`watcher::FsEvent::WeRemoved`-Handler in `connection.rs` hat nur ein
`skwd.wall.we_removed`-UI-Event gefeuert, aber nie den Eintrag aus der
SQLite-DB (`~/.local/share/skwd-daemon/daemon.sqlite`, Tabelle `meta`) oder
die generierten Thumbnails gelöscht — obwohl die dafür nötige Funktion
(`db::delete_meta_by_we_id`) bereits existierte, nur ungenutzt war. Folge:
in Steam/Wallpaper Engine entfernte Workshop-Items blieben dauerhaft im
skwd-wall-Picker sichtbar.

Fix: `WeRemoved`-Handler ruft jetzt `db::delete_meta_by_we_id` und räumt
`thumbs/<we_id>.webp` sowie `thumbs-sm/we-<we_id>.webp` auf — analog zum
bereits vorhandenen `FileRemoved`-Handler für normale (Bild/Video-)Wallpaper.
