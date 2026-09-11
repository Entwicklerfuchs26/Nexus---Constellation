# Split-Tunnel-VPN für nexus: nur explizit gelistete Domains laufen über
# ProtonVPN (o. ä. kostenlosen WireGuard-Anbieter), alles andere normal
# über den regulären Internetzugang. Zwei Nutzerdateien, beide bewusst
# NICHT in Git (siehe .gitignore, Vorlagen liegen als *.example daneben):
#
#   vpn-userdata/split-tunnel-domains.txt
#     Eine Domain pro Zeile -- Jonas editiert direkt, kein Rebuild-Zwang
#     für die Datei selbst, aber "sudo nixos-rebuild switch" ist trotzdem
#     nötig, damit dnsmasq die neue Liste übernimmt (Build-Zeit-Import,
#     kein Live-Reload).
#
#   vpn-userdata/protonvpn.conf
#     Die UNVERÄNDERTE, bei ProtonVPN heruntergeladene WireGuard-Config
#     (Format: Standard wg-quick .conf, [Interface]/[Peer]-Sektionen) --
#     einfach reinkopieren, PrivateKey/Address/PublicKey/Endpoint werden
#     unten automatisch rausgeparst. Keine manuelle Feld-Extraktion nötig.
#
# Technik: dnsmasq mit ipset-Direktive löst gelistete Domains normal auf,
# packt die Ziel-IPs aber zusätzlich in ein ipset. Pakete an IPs in diesem
# ipset bekommen per iptables einen fwmark, ip rule schickt genau diese
# Pakete in eine eigene Routing-Tabelle mit wg-protonvpn als Default-Route
# -- alles andere bleibt auf der normalen Default-Route. Bewusst NICHT die
# automatische allowedIPs-Routen-Injection von networking.wireguard
# genutzt (würde bei "0.0.0.0/0" zum kompletten Tunnel statt Split-Tunnel
# führen) -- allowedIPs ist trotzdem auf 0.0.0.0/0 gesetzt (das braucht
# WireGuard fürs Verschlüsseln beliebiger Ziele), die eigentliche
# Zieleinschränkung passiert ausschließlich über ip rule/ipset unten.
#
# NICHT live getestet (fehlen echte ProtonVPN-Zugangsdaten) -- vor dem
# ersten Rebuild mit aktivierter Config sollte Jonas anwesend/erreichbar
# sein, falls die Routing-Logik nachjustiert werden muss.
{ config, pkgs, lib, ... }:

let
  userDataDir = ../../vpn-userdata;
  domainsFile = "${userDataDir}/split-tunnel-domains.txt";
  protonConfFile = "${userDataDir}/protonvpn.conf";

  hasDomainsFile = builtins.pathExists domainsFile;
  hasProtonConf  = builtins.pathExists protonConfFile;

  domains =
    if hasDomainsFile then
      lib.filter (l: l != "" && !(lib.hasPrefix "#" l))
        (map lib.trim (lib.splitString "\n" (builtins.readFile domainsFile)))
    else [];

  protonConfText = if hasProtonConf then builtins.readFile protonConfFile else "";

  # Extrahiert "Key = Wert" aus dem wg-quick-Format -- funktioniert nur
  # zuverlässig, wenn der Schlüsselname genau einmal in der Datei vorkommt
  # (bei PrivateKey/Address/PublicKey/Endpoint in einer Standard-ProtonVPN-
  # Config der Fall).
  extractField = key: text:
    let m = builtins.match ".*${key}[ \t]*=[ \t]*([^\n\r]*).*" text;
    in if m == null then null else lib.head m;

  protonPrivateKey = extractField "PrivateKey" protonConfText;
  protonAddress    = extractField "Address" protonConfText;
  protonPublicKey  = extractField "PublicKey" protonConfText;
  protonEndpoint   = extractField "Endpoint" protonConfText;

  ipsetName  = "split-tunnel";
  fwmarkHex  = "0x2";
  routeTable = "51820"; # eigene Tabellen-Nummer, kollidiert nicht mit "main"/"default"
in
lib.mkIf hasProtonConf {

  assertions = [
    {
      assertion = protonPrivateKey != null && protonAddress != null
                  && protonPublicKey != null && protonEndpoint != null;
      message = ''
        vpn-userdata/protonvpn.conf gefunden, aber PrivateKey/Address/
        PublicKey/Endpoint konnten nicht alle rausgelesen werden -- Format
        der Datei prüfen (Standard wg-quick .conf erwartet).
      '';
    }
  ];

  environment.systemPackages = [ pkgs.ipset ];

  # ── DNS: dnsmasq statt Direktweiterleitung, füllt das ipset ────────────────
  services.dnsmasq = {
    enable = true;
    settings = {
      server = [ "1.1.1.1" "9.9.9.9" ];
      no-resolv = true;
      ipset = map (d: "/${d}/${ipsetName}") domains;
    };
  };
  # dnsmasq lokal als Resolver nutzen, sonst hat es nichts zu tun.
  networking.nameservers = lib.mkForce [ "127.0.0.1" ];

  systemd.services.split-tunnel-ipset-init = {
    description = "Split-Tunnel ipset anlegen (vor dnsmasq)";
    before  = [ "dnsmasq.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    script = "${pkgs.ipset}/bin/ipset create ${ipsetName} hash:ip -exist";
  };

  # ── WireGuard-Interface ─────────────────────────────────────────────────
  networking.wireguard.interfaces.wg-protonvpn = {
    ips = [ protonAddress ];
    privateKeyFile = pkgs.writeText "wg-protonvpn-key" protonPrivateKey;
    peers = [{
      publicKey  = protonPublicKey;
      endpoint   = protonEndpoint;
      # 0.0.0.0/0 ist noetig, damit WireGuard beliebige Ziele ueber diesen
      # Peer verschluesseln DARF -- die eigentliche Split-Tunnel-Einschraenkung
      # passiert unten ueber ip rule/ipset, NICHT hierueber.
      allowedIPs = [ "0.0.0.0/0" ];
      persistentKeepalive = 25;
    }];
    # Verhindert, dass NixOS aus allowedIPs automatisch eine Default-Route
    # in der Haupt-Tabelle anlegt (sonst waere es ein Voll-Tunnel). Eigene,
    # explizite Routing-Logik statt der impliziten allowedIPs-Route.
    postSetup = ''
      ${pkgs.iproute2}/bin/ip route del default dev wg-protonvpn 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip route add default dev wg-protonvpn table ${routeTable}
      ${pkgs.iproute2}/bin/ip rule add fwmark ${fwmarkHex} table ${routeTable} priority 100
    '';
    postShutdown = ''
      ${pkgs.iproute2}/bin/ip rule del fwmark ${fwmarkHex} table ${routeTable} priority 100 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip route flush table ${routeTable} 2>/dev/null || true
    '';
  };

  # ── Pakete an ipset-Adressen markieren, damit ip rule sie greift ────────
  networking.firewall.extraCommands = ''
    iptables -t mangle -N split-tunnel-mark 2>/dev/null || iptables -t mangle -F split-tunnel-mark
    iptables -t mangle -A split-tunnel-mark -m set --match-set ${ipsetName} dst -j MARK --set-mark ${fwmarkHex}
    iptables -t mangle -A OUTPUT -j split-tunnel-mark
  '';
  networking.firewall.extraStopCommands = ''
    iptables -t mangle -D OUTPUT -j split-tunnel-mark 2>/dev/null || true
    iptables -t mangle -F split-tunnel-mark 2>/dev/null || true
    iptables -t mangle -X split-tunnel-mark 2>/dev/null || true
  '';
}
