#!/usr/bin/env bash

set -u

TAG_PACMAN="󰮯"
TAG_AUR="󰊢"
TAG_FLATPAK="󰏗"

ICON_INSTALL="󰐕"
ICON_UNINSTALL="󰆴"
ICON_UPDATE="󰚰"

run() {
  foot --app-id=package-tui bash -c '
    "$@"
    status=$?
    printf "\nPress any key to close..."
    read -rsn1
    exit "$status"
  ' bash "$@"
}

pick() {
  printf '%s\n' "$@" | sort | fzf --reverse
}

pacman_preview() {
  if pacman -Q "$1" &>/dev/null; then
    printf '󰄬 INSTALLED\n\n'
  else
    printf '󰐕 NOT INSTALLED\n\n'
  fi

  pacman -Si "$1"
}

aur_preview() {
  package=${1#*/}

  if pacman -Q "$package" &>/dev/null; then
    printf '󰄬 INSTALLED\n\n'
  else
    printf '󰐕 NOT INSTALLED\n\n'
  fi

  paru -Si "$package"
}

export -f pacman_preview aur_preview

declare -A actions=(
  ["$ICON_INSTALL Install package"]="install"
  ["$ICON_UNINSTALL Uninstall package"]="uninstall"
  ["$ICON_UPDATE Update"]="update"
)

declare -A managers=(
  ["$TAG_PACMAN Pacman"]="pacman"
  ["$TAG_AUR AUR"]="aur"
  ["$TAG_FLATPAK Flatpak"]="flatpak"
)

while :; do
  clear

  selected=$(pick "${!actions[@]}")
  [[ -z $selected ]] && exit

  action=${actions[$selected]}

  # ── Updates ────────────────────────────────────────

  if [[ $action == update ]]; then
    selected=$(pick \
      "$TAG_PACMAN Pacman" \
      "$TAG_AUR AUR" \
      "$TAG_FLATPAK Flatpak" \
      "$ICON_UPDATE All")

    [[ -z $selected ]] && continue

    case "$selected" in
      *Pacman)
        run sudo pacman -Syu
        ;;

      *AUR)
        run paru -Sua
        ;;

      *Flatpak)
        run flatpak update
        ;;

      *All)
        run bash -c '
          echo -e "\nUpdating Pacman...\n" && sudo pacman -Syu && echo -e "\nUpdating AUR...\n" &&
          paru -Sua && echo -e "\nUpdating Flatpak...\n" &&
          flatpak update
        '
        ;;
    esac

    continue
  fi

  # ── Select manager ────────────────────────────────

  selected=$(pick "${!managers[@]}")
  [[ -z $selected ]] && continue

  manager=${managers[$selected]}

  # ── Pacman ─────────────────────────────────────────

  if [[ $manager == pacman ]]; then

    if [[ $action == install ]]; then
      package=$(
        pacman -Ssq |
          fzf --reverse \
            --preview 'pacman_preview {}'
      )

      [[ -n $package ]] &&
        run sudo pacman -S "$package"

    else
      package=$(
        pacman -Qq |
          fzf --reverse \
            --preview 'pacman -Qi {}'
      )

      [[ -n $package ]] &&
        run sudo pacman -Rns "$package"
    fi

  # ── AUR ────────────────────────────────────────────

  elif [[ $manager == aur ]]; then

    if [[ $action == install ]]; then
      read -rp "Search AUR: " query
      [[ -z $query ]] && continue

      package=$(
        paru -Ssa "$query" |
          fzf --reverse \
            --preview 'aur_preview {}'
      )

      [[ -n $package ]] &&
        run paru -S "${package#*/}"

    else
      package=$(
        paru -Qmq |
          fzf --reverse \
            --preview 'paru -Qi {}'
      )

      [[ -n $package ]] &&
        run paru -Rns "$package"
    fi

  # ── Flatpak ────────────────────────────────────────

  elif [[ $manager == flatpak ]]; then

    if [[ $action == install ]]; then
      package=$(
        flatpak search --columns=application,name "" |
          fzf --reverse
      )

      package=$(awk '{print $1}' <<< "$package")

      [[ -n $package ]] &&
        run flatpak install "$package"

    else
      package=$(
        flatpak list --app --columns=application,name |
          fzf --reverse
      )

      package=$(awk '{print $1}' <<< "$package")

      [[ -n $package ]] &&
        run flatpak uninstall "$package"
    fi

  fi
done
