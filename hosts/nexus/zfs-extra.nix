# Zusatz-Modul NUR für den ZFS-Testinstall auf der 1TB-Platte
# (nixosConfigurations.nexus-1tb-test in flake.nix). Die produktive
# "nexus"-Config (ext4, 512GB) importiert das bewusst NICHT.
{ config, lib, pkgs, userHardware, ... }:

{
  networking.hostId = userHardware.zfsHostId;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

  # Wöchentlicher Scrub + automatisches TRIM, guter Standard für SSDs
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  # Alte 512GB read-only mitmounten -- Übergangshilfe während des Umzugs
  # (Zugriff auf .claude/Chatverlauf, .ssh, sojus-core etc. ohne die alte
  # Platte anzufassen). Read-only zur Sicherheit: die 512GB bleibt der
  # unberührte Fallback, egal was hier passiert. Kann nach Abschluss des
  # Umzugs wieder raus.
  fileSystems."/mnt/alte-platte" = {
    device = "/dev/disk/by-id/ata-Samsung_SSD_860_PRO_512GB_S42YNX0N901164Y-part2";
    fsType = "ext4";
    options = [ "nofail" "ro" "x-systemd.automount" ];
  };
}
