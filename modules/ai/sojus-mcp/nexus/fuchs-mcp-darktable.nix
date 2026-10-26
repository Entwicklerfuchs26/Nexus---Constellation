# Migriert auf mkMcpServer (P2 Punkt 4, 11.09.2026) -- runAsFuchs=true, weil
# das Skript ~/.config/darktable/library.db liest (echtes Home von fuchs,
# nicht das isolierte /var/lib/ eines dedizierten System-Users). Verhalten
# unveraendert: gleicher User, gleiches PATH (pkgs.darktable), gleicher
# ExecStart wie vorher.
import ../modules/mkMcpServer.nix {
  name        = "fuchs-mcp-darktable";
  description = "Fuchs – Darktable Foto-Workflow MCP (HTTP, Port 19011)";
  script      = ../scripts/nexus/mcp-darktable.py;
  port        = 19011;
  host        = "127.0.0.1";
  runAsFuchs  = true;
  extraPath   = pkgs: [ pkgs.darktable ];
  restartSec  = "5s";
}
