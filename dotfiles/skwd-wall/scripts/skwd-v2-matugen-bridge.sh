#!/run/current-system/sw/bin/bash
# skwd-wall v2 -> Matugen-Bridge.
# v2 themt intern (skwd-iris) und triggert Jonas' bestehende Matugen-Kette
# (Waybar/Kitty/Dock/rofi/GTK/...) NICHT. Dieses Skript haengt sich an v2s
# Event-Stream (`skwd-helm watch --exec '<dies> %path%'`) und faehrt pro
# Wallpaper-Wechsel die gleiche Matugen-Pipeline wie frueher matugen-apply.sh.
# Arg $1 = frisch angewandter Wallpaper-Pfad (%path% von skwd-helm).
set -u
WP="${1:-}"
LOG=/home/fuchs/skwd-test.log
export PATH="/etc/profiles/per-user/fuchs/bin:/run/current-system/sw/bin:$PATH"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export HYPRLAND_INSTANCE_SIGNATURE="${HYPRLAND_INSTANCE_SIGNATURE:-$(ls -t /run/user/1000/hypr/ 2>/dev/null | head -1)}"

# Nur Raster-Bilder themen. WE-Szenen/Videos haben keine direkte Bildquelle
# fuer Matugen -> ueberspringen (spaetere Politur: Preview-Frame nutzen).
case "${WP,,}" in
  *.jpg|*.jpeg|*.png|*.webp|*.bmp|*.gif) : ;;
  *) echo "bridge: skip non-image $WP" >> "$LOG"; exit 0 ;;
esac
[ -r "$WP" ] || { echo "bridge: unreadable $WP" >> "$LOG"; exit 0; }

echo "BRIDGE START $(date) $WP" >> "$LOG"
SRC=/home/fuchs/skwd-wall.png
magick "$WP" "$SRC" 2>>"$LOG" || convert "$WP" "$SRC" 2>>"$LOG"
mode="$(cat /home/fuchs/.cache/sojus/colorscheme 2>/dev/null || echo dark)"
matugen -c /home/fuchs/.config/matugen/config.toml image "$SRC" \
  --source-color-index 0 -m "$mode" -t scheme-fidelity >>"$LOG" 2>&1

# Reloads wie in der alten Kette
bash /home/fuchs/.config/matugen/apply-borders.sh >>"$LOG" 2>&1 || true
pkill -USR1 cava 2>/dev/null || true
pkill -USR1 kitty 2>/dev/null || true
pkill -USR2 waybar 2>/dev/null || true
/home/fuchs/.config/matugen/papirus-color.sh >>"$LOG" 2>&1 || true

# Sojus-App-Theme posten (Hintergrund, kurzer Timeout -> blockiert nie)
( curl -s -m 5 -X POST http://192.168.1.26:7430/theme \
    -H "Content-Type: application/json" \
    --data-binary @/home/fuchs/.cache/skwd-wall/colors.json >>"$LOG" 2>&1 ) &
echo "BRIDGE DONE $(date)" >> "$LOG"
