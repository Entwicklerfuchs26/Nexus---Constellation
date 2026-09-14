# Vorlage -- KOPIEREN nach /etc/nixos/user/hardware.nix (AUSSERHALB dieses
# Repos, siehe user/config.example.nix und INSTALL.md).
#
# Maschinenspezifische Hardware-Werte für DIESEN Rechner. Bei mehreren
# Rechnern (siehe hosts/) kann das pro Host unterschiedlich sein --
# einfachster Weg: pro Host ein eigenes hardware-<hostname>.nix anlegen
# und in hosts/<hostname>/host-config.nix das passende importieren.
{
  # Netzwerk-Interface für Wake-on-LAN (ip link zeigt die Namen)
  networkInterface = "eth0";

  # Bluetooth-Geräte, die eine feste Profil-Regel brauchen (z.B. Headset
  # das nicht automatisch ins richtige A2DP-Profil wechselt).
  # MAC-Format wie in PipeWire: mit Unterstrichen statt Doppelpunkten.
  bluetooth = {
    # headsetMac = "AA_BB_CC_DD_EE_FF";
  };

  # Zusätzliche Datenpartitionen, die als /mnt/<name> eingebunden werden
  # sollen. UUID rausfinden mit: lsblk -f
  disks = {
    # dataUuid = "00000000-0000-0000-0000-000000000000";
  };

  # Nur nötig falls du ZFS als Root-Dateisystem nutzt (siehe INSTALL.md,
  # Abschnitt 1TB/ZFS-Umzug). 8 Hex-Zeichen, eindeutig pro Maschine,
  # generieren mit: head -c4 /dev/urandom | od -A none -t x4 | tr -d ' '
  zfsHostId = "00000000";

  # Monitor-Layout (Namen wie in `hyprctl monitors` bzw. `wlr-randr`).
  # Wird aktuell nur als Referenz dokumentiert -- die konkreten Monitor-
  # Zeilen in home/files/hyprland.conf und die Widget-Zuordnung in den
  # Quickshell-Dashboard-/Sidebar-Dateien müssen für dein eigenes Layout
  # von Hand angepasst werden (siehe INSTALL.md).
  monitors = [
    # { name = "DP-1"; resolution = "1920x1080@60"; position = "0x0"; }
  ];
}
