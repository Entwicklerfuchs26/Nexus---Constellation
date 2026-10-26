# Generalisierter Baustein für die ~27 flachen MCP-Server-Module in
# darwin26/*.nix + nexus/*.nix (siehe deren Kopfkommentare/README für den
# Bestand) — P2-Punkt 4 aus dem Sojus-Plan vom 06.09.2026
# (~/Desktop/sojus-plan-p2-p3-p4-2026-09-06.md): diese Dateien sind zu ~90%
# copy-paste desselben User/Group/Service-Skeletts, nur Name/Port/Skript/
# Runtime unterscheiden sich — eine Änderung wie der `tar`-PATH-Fix vom
# 07.09. musste dadurch potenziell 27x nachgezogen werden statt 1x.
#
# Bewusst KEIN Namens-/Präfix-Vorgaben (anders als modules/sojus-mcp.nix,
# das für NEUE instanz-eigene Server gedacht ist und "${instanceName}-mcp-
# ${name}" erzwingt) — hier müssen exakte Bestandsnamen (User, Service,
# Port, Env-Datei-Pfad) reproduzierbar bleiben, um laufende Produktiv-
# Dienste beim Migrieren nicht unter sich wegzuziehen.
#
# Deckt NICHT ab (bewusst außen vor, zu andersartig für einen gemeinsamen
# Nenner ohne Verrenkungen):
#   - die 5 mcp-proxy-Bridge-Dienste (freecad/blender/davinci/obs/
#     filesystem) — verketten zwei Prozesse über `--named-server`, eigene
#     Firewall-/Netzwerk-Eigenheiten.
#   - mcp-approval-service.nix (uvicorn+FastAPI-App, kein MCP-Server im
#     eigentlichen Sinn).
#   - npx-basierte Dienste mit Env-Var-Konfiguration statt CLI-Flags
#     (aktuell nur fuchs-mcp-anilist.nix) — passt nicht zum
#     `--transport/--host/--port`-CLI-Schema unten.
#
# runAsFuchs-Sonderfall: auf nexus laufen mehrere Dienste als echter User
# "fuchs" statt als isolierter System-User, weil sie GUI-Apps/deren
# Config/Sockets im echten Home brauchen (Darktable-Library unter
# ~/.config/darktable, LightBurn-Prefs, Hyprland-Runtime-Dir unter
# /run/user/1000/hypr) — ein dedizierter System-User mit eigenem
# /var/lib/-Home hätte darauf keinen Zugriff. Deshalb hier opt-in
# überschreibbar statt das Standardverhalten (dedizierter User) zu
# erzwingen; wer nichts angibt, bekommt exakt das alte Verhalten.
#
#   import ../modules/mkMcpServer.nix {
#     name = "fuchs-mcp-darktable";
#     description = "Fuchs – Darktable Foto-Workflow MCP";
#     script = ../scripts/nexus/mcp-darktable.py;
#     port = 19011; host = "127.0.0.1";
#     runAsFuchs = true;
#     extraPath = pkgs: [ pkgs.darktable ];
#   }
#
# Nutzung, Grundfall (fastmcp-Skript):
#   import ../modules/mkMcpServer.nix {
#     name = "fuchs-mcp-vikunja";
#     description = "Fuchs – Vikunja MCP Server";
#     script = ../scripts/darwin26/fuchs-mcp-vikunja-server.py;
#     port = 18003; host = "0.0.0.0";
#     environmentFile = "/etc/sojus/fuchs-mcp-vikunja.env";
#     withHttpx = true;
#   }
#
# Nutzung, nextcloud-mcp-server (kein eigenes Skript, Paket IST die App):
#   import ../modules/mkMcpServer.nix {
#     name = "fuchs-mcp-nextcloud-private";
#     description = "...";
#     runtime = "nextcloud-mcp-server";
#     port = 18009; host = "0.0.0.0";
#     environmentFile = "/etc/sojus/fuchs-mcp-nextcloud-private.env";
#   }
#
# Escape-Hatch für Sonderfälle (z.B. abweichende CLI-Reihenfolge):
#   execStart = "..."; -- überschreibt die automatische Konstruktion komplett.
#   execStart = pkgs: "..."; -- gleiches, als Funktion wenn pkgs gebraucht
#     wird (z.B. pkgs.writeShellScript fuer einen Wrapper), da der Aufrufer
#     selbst kein `pkgs` im Scope hat.
{ name
, description
, port
, host              ? "0.0.0.0"
, script            ? null
, runtime           ? "fastmcp"        # "fastmcp" | "nextcloud-mcp-server"
, fastmcpVersion    ? "4.0.3"
, httpxVersion      ? "0.28.1"
, nextcloudMcpVersion ? "0.185.3"
, withHttpx         ? false
, environmentFile   ? null
, extraEnvironment  ? {}
, execStart         ? null             # Escape-Hatch, ueberschreibt alles unten
, restartSec        ? "30s"
, extraAfter        ? []               # zusaetzliche systemd After=-Einheiten
                                         # (z.B. "home-assistant.service")
, runAsFuchs        ? false            # true: als echter User fuchs statt
                                         # dediziertem System-User (siehe
                                         # Kopfkommentar) laufen lassen
, extraPath         ? (pkgs: [])       # Funktion pkgs: [...] fuer
                                         # zusaetzliche PATH-Pakete (z.B.
                                         # pkgs: [ pkgs.darktable ]) --
                                         # als Funktion statt fertiger
                                         # Liste, weil der Aufrufer selbst
                                         # kein `pkgs` im Scope hat (siehe
                                         # Kopfkommentar-Beispiele).
}:
{ config, pkgs, lib, userConfig ? { username = "fuchs"; }, ... }:

let
  scriptFile = lib.optionalString (script != null)
    (toString (pkgs.writeText "${name}-server.py" (builtins.readFile script)));

  builtExecStart =
    if execStart != null then
      (if builtins.isFunction execStart then execStart pkgs else execStart)
    else if runtime == "nextcloud-mcp-server" then
      "${pkgs.uv}/bin/uvx --python ${pkgs.python3}/bin/python3 "
      + "nextcloud-mcp-server==${nextcloudMcpVersion} run "
      + "--host ${host} --port ${toString port} --transport streamable-http"
    else
      "${pkgs.uv}/bin/uvx --python ${pkgs.python3}/bin/python3 "
      + lib.optionalString withHttpx "--with httpx==${httpxVersion} "
      + "fastmcp==${fastmcpVersion} run ${scriptFile} "
      + "--transport streamable-http --host ${host} --port ${toString port}";

  serviceUser  = if runAsFuchs then userConfig.username else name;
  serviceGroup = if runAsFuchs then "users" else name;
  serviceHome  = if runAsFuchs then "/home/${userConfig.username}" else "/var/lib/${name}";
in {
  users.users.${name} = lib.mkIf (!runAsFuchs) {
    isSystemUser = true;
    group        = name;
    home         = "/var/lib/${name}";
    createHome   = true;
  };
  users.groups.${name} = lib.mkIf (!runAsFuchs) {};

  systemd.services.${name} = {
    inherit description;
    after       = [ "network-online.target" ] ++ extraAfter;
    wants       = [ "network-online.target" ];
    wantedBy    = [ "multi-user.target" ];

    path = extraPath pkgs;

    environment = {
      HOME                 = serviceHome;
      UV_PYTHON            = "${pkgs.python3}/bin/python3";
      UV_PYTHON_PREFERENCE = "only-system";
      LD_LIBRARY_PATH = lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib pkgs.zlib pkgs.openssl.out pkgs.glib
      ];
    } // extraEnvironment;

    serviceConfig = {
      Type            = "simple";
      User            = serviceUser;
      Group           = serviceGroup;
      ExecStart       = builtExecStart;
      Restart         = "on-failure";
      RestartSec      = restartSec;
      NoNewPrivileges = true;
      PrivateTmp      = true;
    } // lib.optionalAttrs (environmentFile != null) {
      EnvironmentFile = environmentFile;
    };
  };
}
