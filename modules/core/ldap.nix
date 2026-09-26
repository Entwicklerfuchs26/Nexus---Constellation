{ config, pkgs, ... }:

{
  # SSSD für LDAP Authentifizierung
  # services.sssd.config → hosts/nexus/host-config.nix (Domain, URI, Base-DN)
  services.sssd.enable = true;
  # B-62 (25.09.2026): sssd bindet als Lesekonto reader statt anonym. Passwort NICHT
  # im Nix-Store, sondern in einer root-Datei (0400) außerhalb des Repos. Diese Datei
  # MUSS vor dem Rebuild existieren, sonst startet sssd nicht.
  services.sssd.environmentFile = "/etc/nixos/secrets/sssd-ldap.env";

  # Home-Ordner automatisch erstellen beim ersten Login
  security.pam.services.sddm.makeHomeDir = true;
  security.pam.makeHomeDir.umask = "0077";
}
