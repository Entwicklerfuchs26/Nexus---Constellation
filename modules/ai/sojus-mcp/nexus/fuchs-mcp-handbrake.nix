# Migriert auf mkMcpServer (P2 Punkt 4, 11.09.2026) -- runAsFuchs=true,
# weil Encode-Jobs typischerweise Input-/Output-Pfade unter /home/fuchs
# bekommen (Videos/Downloads) -- ein dedizierter System-User haette darauf
# keinen Zugriff. Verhalten unveraendert: gleicher User, gleiches PATH
# (pkgs.handbrake fuer HandBrakeCLI), gleicher ExecStart wie vorher.
import ../modules/mkMcpServer.nix {
  name        = "fuchs-mcp-handbrake";
  description = "Fuchs – HandBrake Video-Encode MCP (HTTP, Port 19009)";
  script      = ../scripts/nexus/mcp-handbrake.py;
  port        = 19009;
  host        = "127.0.0.1";
  runAsFuchs  = true;
  extraPath   = pkgs: [ pkgs.handbrake ];
  restartSec  = "5s";
}
