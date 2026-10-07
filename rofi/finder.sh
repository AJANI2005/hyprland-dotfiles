#!/usr/bin/env bash
# Minimal rofi file finder using plocate.
# Run: rofi -show find -modi "find:$HOME/.local/share/rofi/finder.sh"
# Prerequisite: sudo pacman -S plocate && sudo updatedb

# A row was selected: open it and quit
if [[ $ROFI_RETV == 1 ]]; then
  setsid -f xdg-open "$1" >/dev/null 2>&1
  exit 0
fi

# Text typed + Enter: search
if [[ $ROFI_RETV == 2 ]]; then
  plocate -i -A -l 200000 -- $1 | awk -v q="${1,,}" '
    { n = split($0, p, "/"); b = tolower(p[n])
      s = (b == q) ? 0 : (index(b, q) == 1) ? 1 : index(b, q) ? 2 : 3
      print s "\t" length($0) "\t" $0 }
  ' | sort -t$'\t' -k1,1n -k2,2n | cut -f3- | head -n 500
  exit 0
fi

# First launch
printf '\0prompt\x1fFind\n'
printf '\0message\x1fType words, press Enter to search\n'
printf 'Type a search and press Enter.\0nonselectable\x1ftrue\n'
