# Migriert auf mkMcpServer (P2 Punkt 4, 11.09.2026) -- runAsFuchs=true, weil
# der Wrapper /run/user/1000/hypr/ lesen muss (Hyprland-Runtime-Signatur),
# was nur als echter User fuchs (uid 1000) funktioniert -- ein dedizierter
# System-User haette dort keinen Zugriff (Verzeichnis ist 0700, Owner
# fuchs). ExecStart bleibt der custom Wrapper, der die Signatur dynamisch
# ermittelt, deshalb execStart als Funktion statt der automatischen
# fastmcp-Konstruktion.
import ../modules/mkMcpServer.nix {
  name        = "fuchs-mcp-hyprland";
  description = "Fuchs – Hyprland MCP (HTTP, Port 19001)";
  port        = 19001;
  host        = "127.0.0.1";
  runAsFuchs  = true;
  restartSec  = "10s";
  extraAfter  = [ "graphical-session.target" ];
  extraEnvironment = {
    XDG_RUNTIME_DIR = "/run/user/1000";
  };
  execStart = pkgs: (toString (pkgs.writeShellScript "start-fuchs-mcp-hyprland" ''
    SIG=$(ls /run/user/1000/hypr/ 2>/dev/null | head -1)
    if [ -n "$SIG" ]; then
      export HYPRLAND_INSTANCE_SIGNATURE="$SIG"
    fi
    exec ${pkgs.uv}/bin/uvx fastmcp==4.0.3 run ${
      toString (pkgs.writeText "fuchs-mcp-hyprland-server.py"
        (builtins.readFile ../scripts/nexus/mcp-hyprland.py))
    } --transport streamable-http --host 127.0.0.1 --port 19001
  ''));
}
