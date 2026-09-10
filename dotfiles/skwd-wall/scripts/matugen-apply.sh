#!/run/current-system/sw/bin/bash
echo "START $(date)" >> /home/fuchs/skwd-test.log
# Sojus-App-Theme: colors.json (Matugen-Palette) steht zu diesem Zeitpunkt
# schon fest (der Daemon schreibt sie vor dem postProcessing-Hook, siehe
# apply.rs run_matugen() vs. run_post_processing()) — im Hintergrund und mit
# kurzem Timeout an sojus-api posten, damit ein nicht erreichbares darwin26
# die restliche Theming-Pipeline (Borders, Waybar, ...) nie blockiert.
(
  /run/current-system/sw/bin/curl -s -m 5 -X POST http://192.168.1.26:7430/theme \
    -H "Content-Type: application/json" \
    --data-binary @/home/fuchs/.cache/skwd-wall/colors.json \
    >> /home/fuchs/skwd-test.log 2>&1
) &
/run/current-system/sw/bin/convert /home/fuchs/.cache/skwd-wall/wallpaper/current.jpg /home/fuchs/skwd-wall.png 2>> /home/fuchs/skwd-test.log
echo "CONVERT DONE" >> /home/fuchs/skwd-test.log
mode="$(cat /home/fuchs/.cache/sojus/colorscheme 2>/dev/null || echo dark)"
/etc/profiles/per-user/fuchs/bin/matugen -c /home/fuchs/.config/matugen/config.toml image /home/fuchs/skwd-wall.png --source-color-index 0 -m "$mode" -t scheme-fidelity >> /home/fuchs/skwd-test.log 2>&1
echo "MATUGEN DONE" >> /home/fuchs/skwd-test.log
export PATH="/run/current-system/sw/bin:$PATH"
export HYPRLAND_INSTANCE_SIGNATURE="${HYPRLAND_INSTANCE_SIGNATURE:-$(ls /run/user/1000/hypr/ 2>/dev/null | head -1)}"
/run/current-system/sw/bin/bash /home/fuchs/.config/matugen/apply-borders.sh >> /home/fuchs/skwd-test.log 2>&1
echo "BORDERS DONE" >> /home/fuchs/skwd-test.log
/run/current-system/sw/bin/pkill -USR1 cava 2>/dev/null
/run/current-system/sw/bin/pkill -USR1 kitty 2>/dev/null
/run/current-system/sw/bin/pkill -USR2 waybar
/home/fuchs/.config/matugen/papirus-color.sh >> /home/fuchs/skwd-test.log 2>&1
if pgrep -f nautilus > /dev/null; then
    nautilus -q
    sleep 1
    nautilus &
fi
echo "DONE $(date)" >> /home/fuchs/skwd-test.log

