{ config, pkgs, ... }:

{
  # SSSD für LDAP Authentifizierung
  # services.sssd.config → hosts/nexus/host-config.nix (Domain, URI, Base-DN)
  services.sssd.enable = true;

  # Home-Ordner automatisch erstellen beim ersten Login
  security.pam.services.sddm.makeHomeDir = true;
  security.pam.makeHomeDir.umask = "0077";
}
