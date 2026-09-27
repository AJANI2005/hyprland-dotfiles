#!/usr/bin/env bash

choice=$(
  printf '%s\n' \
    '󰌾  Lock' \
    '󰐥  Shutdown' \
    '󰜉  Reboot' \
    '󰒲  Suspend' \
    '󰤄  Hibernate' \
    '󰍃  Logout' |
    fzf \
      --height=100% \
      --layout=reverse \
      --prompt='Power > ' \
      --no-multi
) || exit 0

case "$choice" in
  *Lock)
    hyprlock
    ;;

  *Shutdown)
    systemctl poweroff
    ;;

  *Reboot)
    systemctl reboot
    ;;

  *Suspend)
    systemctl suspend
    ;;

  *Hibernate)
    systemctl hibernate
    ;;

  *Logout)
    hyprctl dispatch 'hl.dsp.exit()'
    ;;
esac
