{ pkgs }:

pkgs.writeShellScriptBin "nexus-sys-fetcher" ''
  set -euo pipefail

  iface=$(${pkgs.iproute2}/bin/ip -4 route show default 2>/dev/null | awk '{print $5; exit}')
  if [ -z "''${iface:-}" ]; then
    iface=$(ls /sys/class/net | grep -v '^lo$' | head -1 || true)
  fi

  read_stat() {
    read -r _ u n s i io irq sirq steal _ < /proc/stat
    echo "$((u + n + s + i + io + irq + sirq + steal)) $i"
  }

  read_net() {
    ${pkgs.gawk}/bin/awk -v ifc="''${iface:-}:" '$1==ifc{print $2, $10}' /proc/net/dev
  }

  read -r total1 idle1 <<< "$(read_stat)"
  read -r rx1 tx1 <<< "$(read_net)"

  sleep 0.5

  read -r total2 idle2 <<< "$(read_stat)"
  read -r rx2 tx2 <<< "$(read_net)"

  dtotal=$((total2 - total1))
  didle=$((idle2 - idle1))
  cpu="0"
  if [ "$dtotal" -gt 0 ]; then
    cpu=$(${pkgs.gawk}/bin/awk -v dt="$dtotal" -v di="$didle" 'BEGIN{printf "%.1f", 100*(1-di/dt)}')
  fi

  rx_rate=$(${pkgs.gawk}/bin/awk -v a="''${rx1:-0}" -v b="''${rx2:-0}" 'BEGIN{printf "%.0f", (b-a)/0.5}')
  tx_rate=$(${pkgs.gawk}/bin/awk -v a="''${tx1:-0}" -v b="''${tx2:-0}" 'BEGIN{printf "%.0f", (b-a)/0.5}')

  memtotal=$(${pkgs.gawk}/bin/awk '/^MemTotal:/{print $2}' /proc/meminfo)
  memavail=$(${pkgs.gawk}/bin/awk '/^MemAvailable:/{print $2}' /proc/meminfo)
  ram_pct=$(${pkgs.gawk}/bin/awk -v t="$memtotal" -v a="$memavail" 'BEGIN{printf "%.1f", 100*(t-a)/t}')
  ram_gb=$(${pkgs.gawk}/bin/awk -v t="$memtotal" -v a="$memavail" 'BEGIN{printf "%.2f", (t-a)/1048576}')

  gpu_line=$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits 2>/dev/null || true)
  if [ -n "''${gpu_line:-}" ]; then
    gpu_pct=$(echo "$gpu_line" | ${pkgs.gawk}/bin/awk -F',' '{gsub(/ /,"",$1); print $1}')
    vram_used_mb=$(echo "$gpu_line" | ${pkgs.gawk}/bin/awk -F',' '{gsub(/ /,"",$2); print $2}')
    vram_total_mb=$(echo "$gpu_line" | ${pkgs.gawk}/bin/awk -F',' '{gsub(/ /,"",$3); print $3}')
    gpu_temp=$(echo "$gpu_line" | ${pkgs.gawk}/bin/awk -F',' '{gsub(/ /,"",$4); print $4}')
  else
    gpu_pct="0"
    vram_used_mb="0"
    vram_total_mb="0"
    gpu_temp="0"
  fi
  vram_used_gb=$(${pkgs.gawk}/bin/awk -v m="''${vram_used_mb:-0}" 'BEGIN{printf "%.1f", m/1024}')
  vram_total_gb=$(${pkgs.gawk}/bin/awk -v m="''${vram_total_mb:-0}" 'BEGIN{printf "%.1f", m/1024}')

  cpu_temp=""
  for d in /sys/class/hwmon/hwmon*; do
    n=$(cat "$d/name" 2>/dev/null || true)
    if [ "$n" = "k10temp" ] && [ -f "$d/temp1_input" ]; then
      cpu_temp=$(${pkgs.gawk}/bin/awk -v v="$(cat "$d/temp1_input")" 'BEGIN{printf "%.1f", v/1000}')
      break
    fi
  done
  if [ -z "''${cpu_temp:-}" ]; then
    for z in /sys/class/thermal/thermal_zone*; do
      if [ -f "$z/temp" ]; then
        cpu_temp=$(${pkgs.gawk}/bin/awk -v v="$(cat "$z/temp")" 'BEGIN{printf "%.1f", v/1000}')
        break
      fi
    done
  fi
  [ -z "''${cpu_temp:-}" ] && cpu_temp="0"

  link_speed=$(cat /sys/class/net/"''${iface:-}"/speed 2>/dev/null || true)
  if [[ "''${link_speed:-}" =~ ^[0-9]+$ ]]; then
    link_down_mbps="$link_speed"
    link_up_mbps="$link_speed"
  else
    link_down_mbps=""
    link_up_mbps=""
    iw_link=$(${pkgs.iw}/bin/iw dev "''${iface:-}" link 2>/dev/null || true)
    rx_rate_wifi=$(echo "''${iw_link:-}" | awk '/rx bitrate/{print $3; exit}')
    tx_rate_wifi=$(echo "''${iw_link:-}" | awk '/tx bitrate/{print $3; exit}')
    if [[ "''${rx_rate_wifi:-}" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
      link_down_mbps=$(${pkgs.gawk}/bin/awk -v r="$rx_rate_wifi" 'BEGIN{printf "%d", r}')
    fi
    if [[ "''${tx_rate_wifi:-}" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
      link_up_mbps=$(${pkgs.gawk}/bin/awk -v r="$tx_rate_wifi" 'BEGIN{printf "%d", r}')
    fi
  fi
  [ -z "''${link_down_mbps:-}" ] && link_down_mbps="0"
  [ -z "''${link_up_mbps:-}" ] && link_up_mbps="0"

  echo "''${cpu}|''${ram_pct}|''${ram_gb}|''${gpu_pct}|''${vram_used_gb}|''${vram_total_gb}|''${rx_rate}|''${tx_rate}|''${link_down_mbps}|''${link_up_mbps}|''${cpu_temp}|''${gpu_temp}"
''
