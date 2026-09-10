#!/usr/bin/env bash
set -e
kitty --title "Claude — Boot-Check" -- bash -c '
claude "Ich bin gerade hochgefahren. Bevor du irgendwas anfasst: schau kurz nach, was von der letzten Session offen war (u.a. Hyprland/Waybar/Headphone-Limiter/Workspace-Label-Skripte in /etc/nixos/nixos-config, teilweise noch unstaged/unfertig), fass kurz zusammen was da noch aussteht, und frag mich ob es jetzt weitergehen soll. Fang noch NICHT an zu bauen, nur Status-Check + Rückfrage."
'
# Einmaliger Trigger: nach dem Start selbst deaktivieren, damit es nicht bei
# jedem Boot erneut aufploppt.
systemctl --user disable claude-boot-reminder.service
