#!/usr/bin/env bash
# rofi dmenu wrapper. Config and theme come from ~/.config/rofi.
# Usage: ... | menu.sh [-p placeholder] [-w width_chars] [-l lines] [-h row_height_px] [-i icon_px] [extra rofi args]

overrides=""
icon_args=()
while getopts p:w:l:h:i: opt; do
  case $opt in
    p) overrides+="entry { placeholder: \"$OPTARG\"; } " ;;
    w) overrides+="window { width: calc(${OPTARG}ch + 40px); } " ;;
    l) overrides+="listview { lines: $OPTARG; } " ;;
    h) overrides+="element { height: ${OPTARG}px; } " ;;
    i) overrides+="element-icon { size: ${OPTARG}px; } "
       icon_args=(-show-icons) ;;
    *) exit 2 ;;
  esac
done
shift $((OPTIND - 1))

exec rofi -dmenu \
  ${overrides:+-theme-str "$overrides"} \
  "${icon_args[@]}" \
  "$@"
