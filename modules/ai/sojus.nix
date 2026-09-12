{ config, pkgs, lib, ... }:

let
  safeRebuildScript = pkgs.writeShellScript "safe-rebuild" ''
    #!/usr/bin/env bash
    set -euo pipefail

    DESCRIPTION="''${1:-auto}"
    FLAKE_DIR="/etc/nixos"
    FLAKE_TARGET="''${2:-nexus}"

    log() { echo "[safe-rebuild] $*"; }
    die() { echo "[safe-rebuild] FEHLER: $*" >&2; exit 1; }

    # git als root; safe.directory + expliziter Autor da root != Repo-Eigentümer
    git_fuchs() {
      git -C "$FLAKE_DIR" \
        -c safe.directory="$FLAKE_DIR" \
        -c user.name="Sojus-Agent" \
        -c user.email="sojus@nexus" \
        "$@"
    }

    log "Starte sicheren Rebuild: '$DESCRIPTION'"

    # libgit2 (intern in nix) prüft Repo-Eigentümer – root braucht safe.directory
    git config --global --add safe.directory "$FLAKE_DIR" 2>/dev/null || true

    # ── Pre-rebuild commit ────────────────────────────────────────────────────
    log "Staging alle Änderungen..."
    git_fuchs add -A

    # Nur committen wenn es tatsächlich Änderungen gibt
    if git_fuchs diff --cached --quiet; then
      log "Keine Änderungen im Staging – kein pre-rebuild commit nötig."
    else
      git_fuchs commit -m "pre-rebuild: $DESCRIPTION"
      log "Pre-rebuild commit erstellt."
    fi

    # ── Testbuild (build-vm) ──────────────────────────────────────────────────
    log "Baue VM-Test-Image..."
    sudo nixos-rebuild build-vm --flake "$FLAKE_DIR#$FLAKE_TARGET" \
      || die "build-vm fehlgeschlagen – switch abgebrochen."
    log "VM-Build erfolgreich."

    # ── Switch ────────────────────────────────────────────────────────────────
    log "Führe nixos-rebuild switch durch..."
    sudo nixos-rebuild switch --flake "$FLAKE_DIR#$FLAKE_TARGET" \
      || die "switch fehlgeschlagen – System im alten Zustand."
    log "Switch erfolgreich."

    # ── Post-rebuild commit ───────────────────────────────────────────────────
    git_fuchs add -A
    if git_fuchs diff --cached --quiet; then
      git_fuchs commit --allow-empty -m "post-rebuild: $DESCRIPTION – erfolgreich"
    else
      git_fuchs commit -m "post-rebuild: $DESCRIPTION – erfolgreich"
    fi
    log "Fertig. System läuft auf neuem Build."
  '';

in {
  # ── Sojus Agent User ─────────────────────────────────────────────────────────
  # Echter Login-fähiger User (kein isSystemUser) damit sudo -u sojus -s geht.
  # Kein Passwort gesetzt – Zugriff ausschließlich via: sudo -u sojus -s
  users.groups.sojus = {};

  users.users.sojus = {
    isNormalUser = true;
    description  = "Sojus KI-Agent";
    group        = "sojus";
    home         = "/home/sojus";
    createHome   = true;
    shell        = pkgs.bash;
    # Kein initialPassword / passwordFile → Login nur via sudo -u sojus -s
  };

  # ── ACL-Tools verfügbar halten ────────────────────────────────────────────────
  # setfacl/getfacl für /home/fuchs ACL-Verwaltung
  environment.systemPackages = with pkgs; [ acl ];

  # ── Breite Leserechte für sojus, deklarativ statt imperativ ──────────────────
  # Jonas' Wunsch (zuletzt bestätigt 12.09.2026): sojus soll wirklich überall
  # lesen können, nicht nur /etc/nixos + /home/fuchs -- Begründung: keine
  # anderen echten User auf nexus, SSH-Keys sind passphrasengeschützt.
  #
  # Bisher wurde das IMPERATIV per einmaligem setfacl-Aufruf gesetzt (siehe
  # Claude-Code-Memory feedback_acl_ssh_breakage) -- das hat zwei echte
  # Probleme gezeigt: (1) überlebt keinen nixos-rebuild/Reboot zuverlässig
  # (ACL bzw. deren Maske wurde mehrfach live zurückgesetzt vorgefunden),
  # (2) ein zu breiter rekursiver Lauf hat einmal SSH/GPG/sssd/Samba
  # kaputt gemacht (POSIX-ACL auf einer Datei macht aus OpenSSHs Sicht eine
  # "UNPROTECTED PRIVATE KEY FILE", sssd/Samba interpretieren eine geerbte
  # Default-ACL auf dem Parent-Verzeichnis als "Permissions zu offen").
  #
  # Deshalb hier als activationScript (läuft bei JEDEM nixos-rebuild
  # switch erneut, überlebt also Reboots/Rebuilds automatisch) UND mit
  # einer expliziten Ausschlussliste für alles, was beim letzten Vorfall
  # nachweislich kaputtging -- kein blindes "setfacl -R /".
  #
  # NICHT abgedeckt (bewusst): /proc, /sys, /dev, /run (Pseudo-Dateisysteme,
  # ACLs dort sinnlos/riskant), /nix/store (schon world-readable, keine
  # ACL nötig, und rekursiv would nur Zeit kosten), /root (Root selbst,
  # ist eine echte Rechtegrenze, keine reine Datenfrage).
  #
  # Bekannter Nachteil: das hier läuft bei JEDEM Rebuild neu und geht
  # einmal über praktisch das gesamte Root-Dateisystem -- macht jeden
  # künftigen nixos-rebuild switch auf nexus spürbar länger. Bewusster
  # Trade-off für "wirklich überall", nicht übersehen.
  system.activationScripts.sojusReadAccessEverywhere = {
    deps = [ "users" ];
    text = ''
      ACL=${pkgs.acl}/bin/setfacl
      FIND=${pkgs.findutils}/bin/find

      for entry in /*; do
        name=$(basename "$entry")
        case "$name" in
          proc|sys|dev|run|nix|lost+found|root) continue ;;
        esac
        [ -d "$entry" ] || continue

        # rX: Lesen+Traversieren, aber keine Datei wird dadurch neu
        # ausführbar gemacht, die es vorher nicht schon war.
        $FIND "$entry" -xdev \( \
            -path '*/.ssh' -o \
            -path '*/.gnupg' -o \
            -path '*/.config/kdeconnect' -o \
            -path '*/.claude/daemon' -o \
            -path '/var/lib/sssd' -o \
            -path '/var/lib/samba/private' -o \
            -iname '*.pem' -o \
            -iname '*.key' -o \
            -iname 'id_ed25519*' -o \
            -iname 'id_rsa*' -o \
            -iname 'id_ecdsa*' \
          \) -prune -o -exec $ACL -m u:sojus:rX,d:u:sojus:rX {} + \
          2>/dev/null || true
      done
    '';
  };

  # ── safe-rebuild.sh deployen via Activation Script ───────────────────────────
  # Wird bei jedem nixos-rebuild switch aktuell gehalten.
  # Schreibt aus dem Nix-Store nach /home/sojus/bin/safe-rebuild.sh
  system.activationScripts.sojusBin = {
    deps = [ "users" ];
    text = ''
      install -d -m 750 -o sojus -g sojus /home/sojus/bin
      install -m 750 -o sojus -g sojus \
        ${safeRebuildScript} \
        /home/sojus/bin/safe-rebuild.sh
    '';
  };

  # ── Sudoers-Whitelist für sojus: ENTFERNT (2026-08-22) ────────────────────────
  # Testphase "Sojus von vorne": sojus bekommt stattdessen echten SSH-Zugriff
  # (siehe modules/ai/sojus-ssh-logging.nix) mit vollem Befehls-Logging statt
  # Tier-Gating — aber bewusst OHNE jedes sudo, auch nicht die vorher eng
  # gewhitelisteten Selbstverwaltungs-Befehle (nixos-rebuild, systemctl
  # restart auf sich selbst, sandbox-nexus). Konsequenz: safe-rebuild.sh und
  # fuchs-shells eigene Restart/Rebuild-Fähigkeit funktionieren für sojus
  # nicht mehr — unkritisch, fuchs-shell.service ist im selben Zug ohnehin
  # deaktiviert (siehe nexus/fuchs-shell.nix). Alte Regeln standen bis
  # einschließlich Commit vor diesem hier in der Git-Historie, falls das
  # später wieder gebraucht wird.
}
