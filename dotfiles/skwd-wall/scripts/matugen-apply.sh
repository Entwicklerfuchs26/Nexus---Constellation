#!/run/current-system/sw/bin/bash
echo "START $(date)" >> /home/fuchs/skwd-test.log
/run/current-system/sw/bin/convert /home/fuchs/.cache/skwd-wall/wallpaper/current.jpg /home/fuchs/skwd-wall.png 2>> /home/fuchs/skwd-test.log
echo "CONVERT DONE" >> /home/fuchs/skwd-test.log
/etc/profiles/per-user/fuchs/bin/matugen -c /home/fuchs/.config/matugen/config.toml image /home/fuchs/skwd-wall.png --source-color-index 0 >> /home/fuchs/skwd-test.log 2>&1
echo "MATUGEN DONE" >> /home/fuchs/skwd-test.log
/run/current-system/sw/bin/pkill -USR2 waybar
/home/fuchs/.config/matugen/papirus-color.sh >> /home/fuchs/skwd-test.log 2>&1
if pgrep -f nautilus > /dev/null; then
    nautilus -q
    sleep 1
    nautilus &
fi
echo "DONE $(date)" >> /home/fuchs/skwd-test.log

