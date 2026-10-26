# WireGuard-Admin-Tunnel zum privaten Sojus-Knoten animus (10.10.0.2),
# geroutet über den manus-Hub (10.10.0.1). Eigenes Interface "wg-animus",
# getrennt vom ProtonVPN-Split-Tunnel (wg-protonvpn).
# Privater Schluessel liegt ausserhalb des Repos unter /home/fuchs/wg-configs/.
{ ... }:
{
  networking.wireguard.interfaces.wg-animus = {
    ips = [ "10.10.0.3/24" ];
    privateKeyFile = "/home/fuchs/wg-configs/nexus.key";
    peers = [
      {
        # manus-Hub
        publicKey = "bAJab1TbDnXON/4sOtdSuvPvfsl1UJc3XbO49wSAAng=";
        presharedKeyFile = "/home/fuchs/wg-configs/nexus-manus.psk";  # Defense-in-Depth (14.10.2026)
        allowedIPs = [ "10.10.0.0/24" ];
        endpoint = "192.168.1.45:51820"; # Heimnetz-Test; spaeter MyFRITZ!-Adresse
        persistentKeepalive = 25;
      }
    ];
  };
}
