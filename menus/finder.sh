#!/usr/bin/env bash
# Live file finder: results update as you type. Runs in a terminal window.
#   foot --app-id finder -e ~/.local/share/rofi/finder-live.sh
# Needs: sudo pacman -S fzf plocate && sudo systemctl enable --now plocate-updatedb.timer

if [[ $1 == --search ]]; then   # called by fzf on every keystroke
  read -ra w <<<"$2"
  ((${#w[@]})) || exit 0
  plocate -i -b -A -l 100000 -- "${w[@]}" |
    grep -Ev '/(\.cache|\.git|node_modules)/' |
    awk -v q="${2,,}" '{ n = split($0, p, "/"); b = tolower(p[n])
          s = (b == q) ? 0 : (index(b, q) == 1) ? 1 : index(b, q) ? 2 : 3
          print s "\t" length($0) "\t" $0 }' |
    sort -t$'\t' -k1,1n -k2,2n | cut -f3- | head -n 300 |
    awk -v home="$HOME" '{ n = split($0, p, "/")      # "name  ~/dir <TAB> full path"
          d = substr($0, 1, length($0) - length(p[n]) - 1)
          if (index(d, home) == 1) d = "~" substr(d, length(home) + 1)
          printf "\033[1m%s\033[0m  \033[2m%s\033[0m\t%s\n", p[n], d, $0 }'
  exit 0
fi

out=$(fzf --disabled --expect=alt-enter --ansi --delimiter=$'\t' --with-nth=1 \
  --layout=reverse --border=sharp --padding=1,2 --no-scrollbar --info=inline-right \
  --prompt=$'\uf002  ' --pointer='▌' --header='enter open · alt+enter terminal here · esc close' \
  --color='bg:#0b0b0b,fg:#a3a3a3,fg+:#ffffff,bg+:#1a1a1a,hl:#f87171,hl+:#f87171' \
  --color='prompt:#f87171,pointer:#f87171,border:#f87171,info:#525252,header:#525252,query:#ffffff,gutter:#0b0b0b' \
  --bind "change:reload:$0 --search {q}") || exit 0
key=${out%%$'\n'*}; sel=${out#*$'\n'}; sel=${sel#*$'\t'}

if [[ $key == alt-enter ]]; then
  # open a terminal in the folder (the file's folder, or the folder itself)
  [[ -d $sel ]] && dir=$sel || dir=${sel%/*}
  setsid -f foot --working-directory "${dir:-/}" >/dev/null 2>&1
elif [[ -f $sel && -x $sel ]]; then   # executables run in foot, everything else via xdg-open
  setsid -f foot --hold -e "$sel" >/dev/null 2>&1
else
  setsid -f xdg-open "$sel" >/dev/null 2>&1
fi
