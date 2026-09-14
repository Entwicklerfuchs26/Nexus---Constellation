{ config, pkgs, ... }:

{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  hardware.uinput.enable = true;

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";

  services.printing.enable = true;
  # Drucker-spezifische Konfiguration gehört ins eigene Modul (modules/hardware/printing.nix)

  # Audio mit Pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # Gerätespezifische Wireplumber-Regeln (z. B. Bluetooth-Headset-Profile)
    # → in host-config.nix oder eigenem Modul definieren
  };

  nixpkgs.config.allowUnfree = true;
  # electron-39 ist EOL aber von bitwarden-desktop benötigt
  # electron-40 ist EOL, aber vesktop verlangt ^40.4.0 (electron_42 in nixpkgs bricht den Splash->Main-Übergang)
  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
    "electron-40.10.5"
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.bluetooth.settings = {
    General = {
      Experimental = true;
      ReconnectAttempts = 7;
      ReconnectIntervals = "1,2,4,8,16,32,64";
    };
  };

  services.udev.packages = [ pkgs.openrgb ];
  boot.kernelModules = [ "btusb" "i2c-dev" ];

  programs.nix-ld.enable = true;

  users.groups.i2c = {};
  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
    # Intel AX200 Bluetooth USB-Autosuspend deaktivieren (verhindert zufälliges Verschwinden)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="8087", ATTR{idProduct}=="0029", ATTR{power/autosuspend}="-1"
    # Generic USB3.0-CRW Kartenleser (Realtek) Autosuspend deaktivieren (verhindert Disconnect/Reconnect-Loop beim Kartenzugriff)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="0306", ATTR{power/autosuspend}="-1"
    # Hanvon-Zeichentablett und Logitech-USB-Empfänger werden vom Kernel fälschlich zusätzlich
    # als Joystick erkannt. Das macht die automatische Controller-Erkennung in Minecraft-Mods
    # (z.B. Create: Tweaked Controllers) mehrdeutig, wenn ein echter Joystick (TX16S) angeschlossen ist.
    ATTRS{idVendor}=="28bd", ATTRS{idProduct}=="0202", ENV{ID_INPUT_JOYSTICK}=""
    ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c541", ENV{ID_INPUT_JOYSTICK}=""
    ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c08b", ENV{ID_INPUT_JOYSTICK}=""
  '';

  services.usbmuxd.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  boot.supportedFilesystems = [ "ntfs" ];
  # Kernel-exFAT deaktiviert → fuse-exfat übernimmt (uid/gid funktioniert)
  boot.blacklistedKernelModules = [ "exfat" ];
  environment.systemPackages = with pkgs; [ udisks2 exfat gnome-disk-utility ];

  environment.etc."udisks2/mount_options.conf".text = ''
    [defaults]
    exfat_defaults=uid=$UID,gid=$GID,umask=002
    exfat_allow=uid=$UID,gid=$GID,umask,dmask,fmask,iocharset,errors
  '';

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (
        subject.isInGroup("wheel") &&
        action.id.indexOf("org.freedesktop.udisks2.") == 0
      ) {
        return polkit.Result.YES;
      }
    });
  '';

  # system.stateVersion nicht ändern ohne Migration (nixos-rebuild switch kann Datenverlust verursachen)
  system.stateVersion = "25.11";
}
