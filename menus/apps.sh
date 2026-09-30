#!/usr/bin/env bash
# app-launcher.sh

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

app_dirs=(
  /usr/share/applications
  /usr/local/share/applications
  "$HOME/dotfiles/menus/applications"
  "$HOME/.local/share/applications"
  "$HOME/.local/share/flatpak/exports/share/applications"
  /var/lib/flatpak/exports/share/applications
)


list_apps() {
    for dir in "${app_dirs[@]}"; do
        [ -d "$dir" ] || continue

        for f in "$dir"/*.desktop; do
            [ -e "$f" ] || continue
            grep -q '^NoDisplay=true' "$f" && continue

            name=$(grep -m1 '^Name=' "$f" | cut -d= -f2-)
            [ -n "$name" ] || continue

            icon=$("$SCRIPT_DIR/app-icon.sh" "$name")

            printf '%s  %s\037%s\n' \
                "$icon" \
                "$name" \
                "$(basename "$f")"
        done
    done | sort -u -t $'\037' -k1,1
}

selection=$(
    list_apps |
  fzf \
    --height=100% \
    --layout=reverse \
    --border=none \
    --margin=1 \
    --padding=1 \
    --prompt=' 󰜴 ' \
    --pointer='▌ ' \
    --marker='┃ ' \
    --info=hidden \
    --no-scrollbar \
    --delimiter=$'\037' \
    --with-nth=1
)

[ -n "$selection" ] || exit 0

desktop_id=$(printf '%s' "$selection" | cut -d $'\037' -f2)

setsid -f gtk-launch "${desktop_id%.desktop}" >/dev/null 2>&1
