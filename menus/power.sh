#!/usr/bin/env bash

menu="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/menu.sh"

choice=$(
  printf '%s\n' \
    '󰌾  Lock' \
    '󰐥  Shutdown' \
    '󰜉  Reboot' \
    '󰒲  Suspend' \
    '󰤄  Hibernate' \
    '󰍃  Logout' |
    "$menu" -p Power -l 6
) || exit 0

case "$choice" in
  *Lock)      hyprlock ;;
  *Shutdown)  systemctl poweroff ;;
  *Reboot)    systemctl reboot ;;
  *Suspend)   systemctl suspend ;;
  *Hibernate) systemctl hibernate ;;
  *Logout)    hyprctl dispatch 'hl.dsp.exit()' ;;
esac
