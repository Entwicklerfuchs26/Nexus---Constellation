# Migriert auf mkMcpServer (P2 Punkt 4, 11.09.2026) -- runAsFuchs=true,
# selbes Muster wie darktable/handbrake/lightburn/hyprland (nexus-
# Desktop-Integration). Verhalten unveraendert: gleicher User, gleicher
# ExecStart, gleiches httpx-Pin vom 11.09. wie vorher.
import ../modules/mkMcpServer.nix {
  name        = "fuchs-mcp-libreoffice";
  description = "Fuchs – LibreOffice MCP (HTTP, Port 19004)";
  script      = ../scripts/nexus/mcp-libreoffice.py;
  port        = 19004;
  host        = "127.0.0.1";
  withHttpx   = true;
  runAsFuchs  = true;
}
