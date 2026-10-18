{ config, pkgs, lib, ... }:

# Update-System fuer nexus
# ------------------------
# nexus laeuft rein deklarativ auf nixpkgs-unstable. "Updaten" ist genau EIN
# Vorgang: `nix flake update` (zieht nixpkgs + alle Inputs neu) + rebuild.
# Damit sind ALLE Programme auf einmal aktuell -- kein Programm-fuer-Programm.
#
# Zwei Teile:
#   1. `nexus-update`         -- der Befehl, den Jonas startet, um anzuwenden.
#   2. nexus-update-check     -- woechentlicher User-Timer, der im Hintergrund
#                                das neue System schon VORBAUT (download + build)
#                                und dann per Desktop-Benachrichtigung meldet.
#                                Wendet NICHTS an -- Entscheidung + Passwort
#                                bleiben bei Jonas (der `switch` ist der einzige
#                                Rot-Schritt und laeuft nur ueber sudo).
#
# Reversibel: diese Datei aus den flake.nix-imports nehmen + rebuild. Aendert
# nichts an rpool/home/secrets. Der Timer laeuft als User-Dienst (hat die
# Grafik-Session fuer notify-send und schreibt nichts als root in das Repo).
#
# Spaeterer Ausbau: statt Desktop-Benachrichtigung ein HA-Push aufs Handy --
# dafuer braucht es ein HA-Long-Lived-Token als agenix-Secret (siehe unten
# Markierung "HA-PUSH"). Bewusst noch nicht gebaut (Secret = Rot).

let
  flakeDir = "/etc/nixos/nixos-config";
  flakeTarget = "nexus";
  user = "fuchs";

  # Store-State: vorgebaute Lock + Diff + GC-geschuetzter Build-Output.
  # Liegt in ~/.local/state, damit alles dem User gehoert (kein root im Repo).
  stateDir = "/home/${user}/.local/state/nexus-update";

  # ---- Bildschirm-Benachrichtigung (persistent, wegklickbar, Snooze) ----
  # Eigenes Skript, damit es (a) der Check am Ende detached starten kann und
  # (b) es sich beim Snooze per systemd-run selbst neu terminieren kann.
  # Buttons lassen Jonas bei JEDEM Mal einstellen, wann er wieder erinnert wird.
  notifyScript = pkgs.writeShellApplication {
    name = "nexus-update-notify";
    runtimeInputs = with pkgs; [ libnotify systemd kitty coreutils gnused ];
    text = ''
      set -euo pipefail
      STATE="${stateDir}"

      # Nur melden, wenn wirklich ein Vorbau wartet.
      [ -f "$STATE/pending.lock" ] && [ -e "$STATE/pending-system" ] || exit 0

      SUMMARY="$(grep -c '^\[U' "$STATE/pending.diff" 2>/dev/null || echo "?")"
      STAMP="$(cat "$STATE/pending.stamp" 2>/dev/null || echo '?')"

      # --expire-time=0  -> bleibt stehen bis Jonas reagiert/wegklickt (swaync).
      # --wait           -> blockiert und gibt den geklickten Action-Key aus;
      #                     weggeklickt/geschlossen -> leere Ausgabe.
      ACTION="$(notify-send --wait --urgency=normal --expire-time=0 \
        --icon=system-software-update --app-name="nexus-update" \
        --action="open=Jetzt updaten" \
        --action="1h=In 1 h" \
        --action="tom=Morgen" \
        --action="week=Naechste Woche" \
        "Nexus: Updates bereit" \
        "$SUMMARY Pakete vorgebaut (vom $STAMP). Wegklicken schliesst nur -- Update bleibt bereit." \
        2>/dev/null)" || true

      case "$ACTION" in
        open) exec kitty --title "nexus-update" -e nexus-update ;;
        1h)   REMIND="1h"  ;;
        tom)  REMIND="24h" ;;
        week) REMIND="7d"  ;;
        *)    exit 0 ;;   # weggeklickt/geschlossen -> erst naechster Wochen-Check
      esac

      # Snooze: dieselbe Benachrichtigung ($0 = dieses Skript) nach REMIND erneut.
      systemd-run --user --quiet --collect \
        --on-active="$REMIND" --timer-property=AccuracySec=1min \
        "$0" || true
    '';
  };

  # ---- Hintergrund-Check: vorbauen, dann melden -------------------------
  checkScript = pkgs.writeShellApplication {
    name = "nexus-update-check";
    runtimeInputs = with pkgs; [ nix git nvd coreutils gnused systemd ];
    text = ''
      set -euo pipefail

      FLAKE_DIR="${flakeDir}"
      TARGET="${flakeTarget}"
      STATE="${stateDir}"
      TOPLEVEL=".#nixosConfigurations.$TARGET.config.system.build.toplevel"

      mkdir -p "$STATE"
      cd "$FLAKE_DIR"

      # flake.lock gehoert zum Repo und soll durch den Check NICHT dauerhaft
      # veraendert werden -- wir sichern, updaten, bauen, und stellen wieder her.
      # Die neue Lock + der fertige Build landen im State fuer `nexus-update`.
      cp -f flake.lock "$STATE/lock.before"

      # Inputs aktualisieren (schreibt flake.lock neu).
      nix flake update 2>&1 | sed 's/^/[flake-update] /' || true

      if git diff --quiet -- flake.lock 2>/dev/null; then
        echo "Keine Updates -- flake.lock unveraendert."
        git checkout -- flake.lock 2>/dev/null || cp -f "$STATE/lock.before" flake.lock
        rm -f "$STATE/pending.lock" "$STATE/pending.diff" "$STATE/pending.stamp"
        exit 0
      fi

      echo "Updates verfuegbar -- baue neues System vor (download + build) ..."
      # Baut das neue Toplevel in den Store und setzt einen GC-Root
      # ($STATE/pending-system), damit der Build bis zum Anwenden erhalten bleibt.
      if ! nix build "$TOPLEVEL" --out-link "$STATE/pending-system" 2>&1 \
            | sed 's/^/[build] /'; then
        echo "Vorbau fehlgeschlagen -- stelle flake.lock wieder her, keine Meldung."
        git checkout -- flake.lock 2>/dev/null || cp -f "$STATE/lock.before" flake.lock
        exit 1
      fi

      # Menschlich lesbares "was aendert sich".
      nvd diff /run/current-system "$STATE/pending-system" > "$STATE/pending.diff" 2>/dev/null || true

      # Neue Lock aufheben, Repo wieder sauber machen.
      cp -f flake.lock "$STATE/pending.lock"
      git checkout -- flake.lock 2>/dev/null || cp -f "$STATE/lock.before" flake.lock

      date '+%Y-%m-%d %H:%M' > "$STATE/pending.stamp"

      # Benachrichtigung detached als eigene transiente Unit starten, damit der
      # oneshot-Check sofort fertig ist und die --wait-Notify beliebig lang steht.
      systemd-run --user --quiet --collect \
        --unit="nexus-update-notify-now" \
        ${notifyScript}/bin/nexus-update-notify || true

      echo "Fertig: Update vorgebaut, Benachrichtigung geschickt."
    '';
  };

  # ---- Der Befehl: anwenden (Jonas startet ihn) -------------------------
  updateScript = pkgs.writeShellApplication {
    name = "nexus-update";
    runtimeInputs = with pkgs; [ nix git nvd coreutils gnused nixos-rebuild ];
    text = ''
      set -euo pipefail

      FLAKE_DIR="${flakeDir}"
      TARGET="${flakeTarget}"
      STATE="${stateDir}"
      FRESH=0
      [ "''${1:-}" = "--fresh" ] && FRESH=1

      cd "$FLAKE_DIR"

      echo "==> Divergenz-Check (git fetch) ..."
      if git fetch --quiet 2>/dev/null; then
        LOCAL="$(git rev-parse @ 2>/dev/null || echo x)"
        REMOTE="$(git rev-parse '@{u}' 2>/dev/null || echo x)"
        BASE="$(git merge-base @ '@{u}' 2>/dev/null || echo x)"
        if [ "$LOCAL" != "$REMOTE" ] && [ "$REMOTE" != "x" ]; then
          if [ "$LOCAL" = "$BASE" ]; then
            echo "!! Remote ist voraus -- erst 'git pull' (sonst Divergenz)."; exit 1
          elif [ "$REMOTE" = "$BASE" ]; then
            echo "   (lokal ist voraus, wird am Ende gepusht)"
          else
            echo "!! Lokal UND Remote divergiert -- bitte manuell aufloesen."; exit 1
          fi
        fi
      else
        echo "   (git fetch nicht moeglich -- offline? mache lokal weiter)"
      fi

      USE_PENDING=0
      if [ "$FRESH" = "0" ] && [ -f "$STATE/pending.lock" ] && [ -e "$STATE/pending-system" ]; then
        USE_PENDING=1
      fi

      if [ "$USE_PENDING" = "1" ]; then
        echo "==> Vorgebautes Update gefunden (vom $(cat "$STATE/pending.stamp" 2>/dev/null || echo '?')):"
        echo
        cat "$STATE/pending.diff" 2>/dev/null || echo "(kein Diff gespeichert)"
        echo
        cp -f "$STATE/pending.lock" flake.lock
      else
        echo "==> Kein Vorbau da (oder --fresh) -- aktualisiere jetzt live ..."
        nix flake update
        if git diff --quiet -- flake.lock; then
          echo "Keine Updates verfuegbar. Alles aktuell."; exit 0
        fi
        echo "==> Baue neues System (download + build) ..."
        nix build ".#nixosConfigurations.$TARGET.config.system.build.toplevel" \
          --out-link "$STATE/pending-system"
        echo; echo "==> Was sich aendert:"; echo
        nvd diff /run/current-system "$STATE/pending-system" || true
        echo
      fi

      printf '==> Anwenden (sudo nixos-rebuild switch -- fragt dein Passwort)? [j/N] '
      read -r ans
      case "$ans" in
        j|J|y|Y) : ;;
        *) echo "Abgebrochen. flake.lock zuruecksetzen ..."; git checkout -- flake.lock; exit 0 ;;
      esac

      echo "==> nixos-rebuild switch ..."
      sudo nixos-rebuild switch --flake ".#$TARGET"

      echo "==> Committen & pushen ..."
      git add flake.lock
      git commit -m "flake.lock: Update $(date '+%Y-%m-%d')" || echo "(nichts zu committen)"
      git push || echo "!! push fehlgeschlagen -- bitte manuell pushen."

      rm -f "$STATE/pending.lock" "$STATE/pending.diff" "$STATE/pending.stamp" "$STATE/pending-system"
      echo "==> Fertig. System aktuell."
    '';
  };

in
{
  environment.systemPackages = [ updateScript checkScript notifyScript ];

  # Woechentlicher Vorbau-Check als USER-Dienst (hat Grafik-Session fuer
  # notify-send, schreibt als fuchs ins Repo -- kein root).
  systemd.user.services.nexus-update-check = {
    description = "Nexus: Updates pruefen und vorbauen";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${checkScript}/bin/nexus-update-check";
      # Nice/IO-niedrig: stoert das Arbeiten nicht.
      Nice = 15;
      IOSchedulingClass = "idle";
    };
    path = [ pkgs.nix pkgs.git pkgs.nvd pkgs.coreutils pkgs.gnused pkgs.systemd ];
    # Session-Bus/WAYLAND_DISPLAY fuer notify-send sind im User-Dienst vorhanden
    # (swaync laeuft als User-Dienst -> Umgebung ist importiert).
  };

  systemd.user.timers.nexus-update-check = {
    description = "Nexus: woechentlicher Update-Check";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Mon 12:00";
      # PC nachts aus -> verpasste Laeufe werden beim naechsten Login nachgeholt.
      Persistent = true;
      # Nicht sofort beim Login losrennen, erst ein paar Minuten spaeter.
      OnStartupSec = "10min";
      RandomizedDelaySec = "30min";
    };
  };

  # --- HA-PUSH (spaeterer Ausbau, bewusst noch nicht aktiv) --------------
  # Um statt/zusaetzlich zur Desktop-Benachrichtigung ein Push aufs Handy zu
  # schicken: HA-Long-Lived-Token als agenix-Secret ablegen und im checkScript
  # vor dem notify-send ein:
  #   curl -s -X POST -H "Authorization: Bearer $(cat <secret>)" \
  #     -H 'Content-Type: application/json' \
  #     -d '{"message":"Nexus: Updates bereit","title":"Nexus"}' \
  #     http://darwin26:8123/api/services/notify/mobile_app_<geraet>
  # ergaenzen. Secret = Rot -> erst mit Freigabe.
}
