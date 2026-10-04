#!/usr/bin/env bash

choice=$(
  printf '%s\n' \
    '󰌾  Lock' \
    '󰐥  Shutdown' \
    '󰜉  Reboot' \
    '󰒲  Suspend' \
    '󰤄  Hibernate' \
    '󰍃  Logout' |
    fuzzel --dmenu --prompt='Power > ' --lines=6
) || exit 0

case "$choice" in
  *Lock)      hyprlock ;;
  *Shutdown)  systemctl poweroff ;;
  *Reboot)    systemctl reboot ;;
  *Suspend)   systemctl suspend ;;
  *Hibernate) systemctl hibernate ;;
  *Logout)    hyprctl dispatch 'hl.dsp.exit()' ;;
esac
