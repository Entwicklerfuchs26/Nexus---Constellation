# Vorlage -- KOPIEREN nach /etc/nixos/user/config.nix (AUSSERHALB dieses
# Repos, siehe INSTALL.md):
#   mkdir -p /etc/nixos/user
#   cp user/config.example.nix /etc/nixos/user/config.nix
#   cp user/hardware.example.nix /etc/nixos/user/hardware.nix
# Muss außerhalb des Repos liegen, sonst sieht der Flake-Build die Datei
# nicht (pure-eval liest nur git-getrackte Dateien -- gleiches Muster wie
# die custom-fonts/aniworld-dl-src-Inputs in flake.nix).
#
# Enthält alles, was an DICH bzw. an deinen Haushalt/deine Community
# gebunden ist -- unabhängig davon auf welcher Maschine es läuft.
# Maschinenspezifische Hardware-Werte (Monitore, MAC-Adressen, Disk-IDs)
# stehen separat in hardware.nix.
{
  # Dein Login-Username auf diesem Rechner (users.users.<username>)
  username = "meinuser";

  # Klarname, taucht z.B. als users.users.<username>.description auf
  fullName = "Vorname Nachname";

  # Kontakt-E-Mail, z.B. für Git-Commits
  email = "ich@example.com";

  # Git-Autor (falls abweichend vom echten Namen, z.B. GitHub-Handle)
  gitAuthorName = "meinuser";
  gitAuthorEmail = "ich@example.com";

  # Hostname dieser Maschine (muss zum hosts/<hostname>/-Ordner passen)
  hostName = "meinpc";

  # Eigene LAN-IP dieser Maschine (nur nötig falls du das Sojus-Core-MCP-
  # Repo mit einbindest, für dessen Firewall-Regeln)
  nexusIp = "192.168.1.10";

  # Interne Domain, unter der deine selbst gehosteten Dienste laufen
  # (Nextcloud, Vikunja, etc.) -- leer lassen ("") wenn nicht vorhanden.
  baseDomain = "example.com";

  # LAN-IP deines Homeservers/NAS, falls vorhanden (für /etc/hosts-Einträge)
  homeserverIp = "192.168.1.10";

  # Nur relevant falls du das Sojus-Core-MCP-Repo einbindest: Shared-Secret
  # zwischen den MCP-Servern auf dieser Maschine und mcp-approval-service
  # auf deinem Homeserver -- auf beiden Seiten identisch setzen.
  mcpApprovalToken = "change-me";

  # Pfad zum nixos-config-Repo auf diesem Host (für Sojus-Core-Sandbox-Sync)
  nixosConfigPath = "/etc/nixos/nixos-config";

  # Kanal-Name für ntfy.sh-Push-Benachrichtigungen (frei wählbar)
  ntfyChannel = "";

  # LDAP/SSSD-Authentifizierung gegen einen eigenen Verzeichnisdienst.
  # enable = false lässt das komplette Modul inaktiv.
  ldap = {
    enable = false;
    domain = "example.com";
    uri = "ldap://ldap.example.com:389";
    searchBase = "ou=users,dc=example,dc=com";
    bindDn = "cn=admin,dc=example,dc=com";
  };

  # Optionaler SFTP-Mount zu einem privaten Cloud-Storage-Anbieter.
  # enable = false lässt das komplette Modul inaktiv.
  sftpRemote = {
    enable = false;
    mountPoint = "/mnt/remote";
    remoteUser = "";
    remoteHost = "";
    remotePort = 22;
    hostPublicKey = ""; # ssh-keyscan -p <port> <host>
  };
}
