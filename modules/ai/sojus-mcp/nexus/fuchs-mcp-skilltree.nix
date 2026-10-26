# Migriert auf mkMcpServer (P2 Punkt 4, 11.09.2026) -- runAsFuchs=true,
# selbes Muster wie darktable/handbrake/lightburn/hyprland (nexus-
# Desktop-Integration). Verhalten unveraendert: gleicher User, gleicher
# ExecStart, gleiches httpx-Pin vom 11.09. wie vorher.
#
# Setzt voraus, dass skill-tree.service (User-Unit, ~/.config/systemd/user/)
# laeuft — kein systemuebergreifender After= moeglich (anderer systemd-
# Scope), gleiches Muster wie OBS/Blender/FreeCAD: App muss selbst laufen.
import ../modules/mkMcpServer.nix {
  name        = "fuchs-mcp-skilltree";
  description = "Fuchs – Skill Tree MCP via Express-API (HTTP, Port 19013)";
  script      = ../scripts/nexus/mcp-skill-tree.py;
  port        = 19013;
  host        = "127.0.0.1";
  withHttpx   = true;
  runAsFuchs  = true;
}
