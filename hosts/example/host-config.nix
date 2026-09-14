# Vorlage für einen neuen Host. Kopiert nach hosts/<hostname>/host-config.nix
# (siehe INSTALL.md). Alle persönlichen/maschinenspezifischen Werte kommen
# aus userConfig/userHardware (/etc/nixos/user/, siehe dortige .example.nix-
# Dateien) -- diese Datei selbst bleibt generisch. Manche Blöcke unten sind
# nur Beispiele für dieses eine Referenzsystem (Samba-Scan-Freigabe,
# zusätzliche Datenpartitionen) -- weglassen wenn nicht gebraucht.
{ config, lib, pkgs, userConfig, userHardware, ... }:

{
  networking.hostName = userConfig.hostName;

  networking.interfaces.${userHardware.networkInterface} = {
    wakeOnLan.enable = true;
  };

  security.sudo.extraRules = [{
    users = [ userConfig.username ];
    commands = [
      {
        command = "/run/current-system/sw/bin/shutdown";
        options = [ "NOPASSWD" ];
      }
      # nixos-rebuild dry-run: liest nur, baut nichts, ändert nichts am System
      {
        command = "/run/current-system/sw/bin/nixos-rebuild dry-run *";
        options = [ "NOPASSWD" ];
      }
      {
        command = "/run/current-system/sw/bin/nixos-rebuild dry-run";
        options = [ "NOPASSWD" ];
      }
    ];
  }];

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;

  # Eigenes internes Root-CA-Zertifikat, falls du selbst gehostete Dienste
  # per HTTPS mit eigener CA betreibst. Auskommentiert lassen wenn nicht
  # zutreffend, sonst eigenes Zertifikat unter certs/ ablegen.
  # security.pki.certificateFiles = [ ../../certs/meine-ca.crt ];

  # /etc/hosts-Einträge für deine selbst gehosteten Dienste (nur wenn
  # userConfig.baseDomain gesetzt ist).
  networking.hosts = lib.optionalAttrs (userConfig.baseDomain != "") {
    "${userConfig.homeserverIp}" = map (sub: "${sub}.${userConfig.baseDomain}") [
      "cloud"
      "n8n"
      "media"
      "photos"
      "tasks"
      "home"
    ];
  };

  # Bluetooth-Headset: A2DP-Profil erzwingen (nur falls in
  # userHardware.bluetooth.boseHeadsetMac konfiguriert)
  services.pipewire.wireplumber.extraConfig = lib.optionalAttrs (userHardware.bluetooth ? boseHeadsetMac) {
    "51-bluez-headset-a2dp" = {
      "monitor.bluez.rules" = [
        {
          matches = [
            { "device.name" = "bluez_card.${userHardware.bluetooth.boseHeadsetMac}"; }
          ];
          actions = {
            update-props = {
              "bluez5.auto-connect" = [ "a2dp_sink" ];
              "device.profile" = "a2dp-sink";
            };
          };
        }
      ];
    };
  };

  # Beispiel: zusätzliche Datenpartition, nur falls userHardware.disks.dataUuid
  # gesetzt ist. UUID rausfinden mit: lsblk -f
  fileSystems."/mnt/data" = lib.mkIf (userHardware.disks ? dataUuid) {
    device = "/dev/disk/by-uuid/${userHardware.disks.dataUuid}";
    fsType = "ext4";
    options = [ "defaults" "nofail" "noauto" ];
  };

  # SSSD/LDAP-Authentifizierung (nur falls userConfig.ldap.enable = true)
  services.sssd.config = lib.mkIf userConfig.ldap.enable ''
    [sssd]
    domains = ${userConfig.ldap.domain}
    services = nss, pam

    [domain/${userConfig.ldap.domain}]
    id_provider = ldap
    auth_provider = ldap
    ldap_uri = ${userConfig.ldap.uri}
    ldap_search_base = ${userConfig.ldap.searchBase}
    ldap_bind_dn = ${userConfig.ldap.bindDn}
    ldap_bind_authtok_type = password
    ldap_user_object_class = inetOrgPerson
    ldap_user_name = uid
    enumerate = true
    cache_credentials = true
  '';

  # Hauptbenutzer
  users.users.${userConfig.username} = {
    isNormalUser = true;
    description = userConfig.fullName;
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "input"
      "bluetooth"
      "i2c"
      "docker"
    ];
    shell = pkgs.bash;
  };
}
