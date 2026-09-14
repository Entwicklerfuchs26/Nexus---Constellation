# Zusatz-Modul für die aktive ZFS-Installation auf der 1TB-Platte
# (nixosConfigurations.nexus). nexus-512-fallback (die alte ext4-Platte)
# importiert das bewusst NICHT.
{ config, lib, pkgs, userHardware, ... }:

{
  networking.hostId = userHardware.zfsHostId;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

  # Wöchentlicher Scrub + automatisches TRIM, guter Standard für SSDs
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  # Die alte 512GB bewusst NICHT in fileSystems eintragen -- so bleibt sie
  # für udisks/Nautilus ein ganz normales Wechsellaufwerk (Sidebar-Eintrag,
  # ein Klick zum Mounten), statt als System-Mount fest eingebunden zu sein.
}
