# Migriert auf mkMcpServer (P2 Punkt 4, 11.09.2026) -- runAsFuchs=true,
# weil das Skript ~/.config/LightBurn/prefs.ini und Projektordner unter
# ~/Dokumente, ~/Desktop etc. liest (echtes Home von fuchs). lightburn ist
# proprietaer/unfree und nicht ueber pkgs verfuegbar, deshalb kein
# extraPath -- lightburn_open() gibt bei fehlendem Binary einen graceful
# Error zurueck (wie vorher).
import ../modules/mkMcpServer.nix {
  name        = "fuchs-mcp-lightburn";
  description = "Fuchs – LightBurn Laser-CAD MCP (HTTP, Port 19010)";
  script      = ../scripts/nexus/mcp-lightburn.py;
  port        = 19010;
  host        = "127.0.0.1";
  runAsFuchs  = true;
  restartSec  = "10s";
}
