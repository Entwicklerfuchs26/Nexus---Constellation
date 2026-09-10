{ config, pkgs, lib, ... }:

let
  # Loggt jeden per SSH als sojus ausgeführten Befehl ins systemd-Journal
  # (journalctl -t sojus-ssh-cmd) und führt ihn danach unverändert aus.
  # Bewusst kein Tier-Gating/Blocking wie bei fuchs-shell — Testphase:
  # erst alles zulassen + mitschneiden, später gezielt einschränken.
  sshCommandLogger = pkgs.writeShellScript "sojus-ssh-command-logger" ''
    #!/usr/bin/env bash
    set -u
    printf '%s\n' "$SSH_ORIGINAL_COMMAND" | ${pkgs.systemd}/bin/systemd-cat -t sojus-ssh-cmd -p info
    eval "$SSH_ORIGINAL_COMMAND"
  '';
in {
  services.openssh.extraConfig = ''
    Match User sojus
      ForceCommand ${sshCommandLogger}
      PermitTTY no
  '';
}
