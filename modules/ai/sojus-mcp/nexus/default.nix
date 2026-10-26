# Sojus Nexus-Module: alle 13 MCP-Services (stdio→HTTP) + Firewall-Ports
{ config, pkgs, lib, userConfig, ... }:

{
  imports = [
    ./fuchs-mcp-filesystem.nix   # Port 9000 – Dateisystem (mcp-proxy → npx)
    ./fuchs-mcp-hyprland.nix     # Port 9001 – Hyprland WM
    ./fuchs-mcp-vivaldi.nix      # Port 9002 – Vivaldi Browser CDP
    # ./fuchs-mcp-obs.nix        # #182 DEAKTIVIERT 26.09.2026: agenix-Secret
    #   fuchs-mcp-obs-env.age ist für die ALTEN Host-Keys verschlüsselt (ZFS-Umzug
    #   14.09.) → nicht mehr entschlüsselbar, brach JEDEN nexus-Rebuild ab.
    #   Reaktivieren: OBS-WebSocket-PW neu setzen, `agenix -e secrets/fuchs-mcp-obs-env.age`
    #   mit aktuellem Host-Key neu verschlüsseln, dann diese Zeile einkommentieren.
    ./fuchs-mcp-libreoffice.nix  # Port 9004 – LibreOffice Writer
    ./fuchs-mcp-freecad.nix      # Port 9005 – FreeCAD (mcp-proxy → uvx)
    ./fuchs-mcp-davinci.nix      # Port 9006 – DaVinci Resolve (mcp-proxy → uvx)
    ./fuchs-mcp-blender.nix      # Port 9007 – Blender 3D (mcp-proxy → uvx)
    ./fuchs-mcp-stellarium.nix   # Port 9008 – Stellarium Planetarium
    ./fuchs-mcp-handbrake.nix    # Port 9009 – HandBrake Video-Encode
    ./fuchs-mcp-lightburn.nix    # Port 9010 – LightBurn Laser-CAD
    ./fuchs-mcp-darktable.nix    # Port 9011 – Darktable Fotografie
    ./fuchs-mcp-skilltree.nix    # Port 9013 – Skill Tree (mcp-proxy → uvx)
    ./fuchs-shell.nix            # Port 8012 – Shell-Zugriff (User sojus, nicht fuchs!)
    ./mcp-approval-proxy.nix     # Phase 2 Tier-Gate vor 9000-9011 (fuchs-shell hat eigenes aus Phase 1)
    ./sandbox-nexus-container.nix        # sandbox-nexus Testcontainer (Kopie von nixos-config)
    ./fuchs-sandbox-control-nexus.nix    # Port 9012 – MCP-Steuerung fuer sandbox-nexus (User sojus)
    ./fuchs-sandbox-nexus-access.nix     # NOPASSWD-sudo fuer fuchs, nur sandbox-nexus-Container
  ];

  # ── Firewall: MCP-Ports nur für darwin26 + nexus selbst ─────────────────────
  # Services binden auf 192.168.1.40. Erlaubt sind ausschließlich:
  #   192.168.1.26  – darwin26 / Sojus Core
  #   192.168.1.40  – nexus selbst (Claude Code lokal)
  # Alle anderen IPs im LAN werden abgewiesen (TCP RST + Log).
  # 8012 (fuchs-shell) läuft über dieselbe Chain wie 9000-9011 — gerade bei
  # Shell-Zugriff darf das nicht übers allgemeine allowedTCPPorts pauschal offen sein.
  networking.firewall.extraCommands = ''
    # Dedizierte Chain anlegen (oder leeren wenn Neustart)
    iptables -N mcp-sojus-filter 2>/dev/null || iptables -F mcp-sojus-filter

    iptables -A mcp-sojus-filter -s ${userConfig.homeserverIp} -j nixos-fw-accept  # Homeserver
    iptables -A mcp-sojus-filter -s ${userConfig.nexusIp} -j nixos-fw-accept  # nexus selbst
    iptables -A mcp-sojus-filter -j nixos-fw-log-refuse              # alle anderen

    # In nixos-fw einhängen (vor dem Default-Drop, da extraCommands vor finalem Reject läuft)
    iptables -A nixos-fw -p tcp --dport 9000:9011 -j mcp-sojus-filter
    iptables -A nixos-fw -p tcp --dport 8012      -j mcp-sojus-filter
    iptables -A nixos-fw -p tcp --dport 9012      -j mcp-sojus-filter
    iptables -A nixos-fw -p tcp --dport 9013      -j mcp-sojus-filter
  '';

  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -p tcp --dport 9000:9011 -j mcp-sojus-filter 2>/dev/null || true
    iptables -D nixos-fw -p tcp --dport 8012      -j mcp-sojus-filter 2>/dev/null || true
    iptables -D nixos-fw -p tcp --dport 9012      -j mcp-sojus-filter 2>/dev/null || true
    iptables -D nixos-fw -p tcp --dport 9013      -j mcp-sojus-filter 2>/dev/null || true
    iptables -F mcp-sojus-filter 2>/dev/null || true
    iptables -X mcp-sojus-filter 2>/dev/null || true
  '';
}
