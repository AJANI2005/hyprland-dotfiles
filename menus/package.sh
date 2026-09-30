#!/usr/bin/env bash

set -u


TAG_PACMAN="󰮯"
TAG_AUR="󰊢"
TAG_FLATPAK="󰏗"

ICON_INSTALL="󰐕"
ICON_UNINSTALL="󰆴"
ICON_UPDATE="󰚰"
ICON_CLEAN="󰩹"


# ── Helpers ──────────────────────────────────────────

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
  printf '%s\n' "$@" |
    fzf \
      --height=100% \
      --reverse \
      --border=none \
      --margin=1 \
      --prompt="> " \
      --pointer="▌ " \
      --marker="┃ " \
      --info=hidden
}


# ── Previews ─────────────────────────────────────────

pacman_preview() {
  pacman -Q "$1" &>/dev/null &&
    printf '󰄬 INSTALLED\n\n' ||
    printf '󰐕 NOT INSTALLED\n\n'

  pacman -Si "$1"
}

aur_preview() {
  local package=${1#*/}

  pacman -Q "$package" &>/dev/null &&
    printf '󰄬 INSTALLED\n\n' ||
    printf '󰐕 NOT INSTALLED\n\n'

  paru -Si "$package"
}

export -f pacman_preview aur_preview


# ── Pacman ───────────────────────────────────────────

install_pacman() {
  local package

  package=$(
    pacman -Ssq |
      fzf \
        --reverse \
        --preview 'pacman_preview {}'
  )

  [[ -n $package ]] &&
    run sudo pacman -S "$package"
}

uninstall_pacman() {
  local package

  package=$(
    pacman -Qqe |
      fzf \
        --reverse \
        --preview 'pacman -Qi {}'
  )

  [[ -n $package ]] &&
    run sudo pacman -Rns "$package"
}

update_pacman() {
  run sudo pacman -Syu
}

cleanup_pacman() {
  local orphans

  orphans=$(pacman -Qdtq)

  if [[ -n $orphans ]]; then
    run sudo pacman -Rns $orphans
  else
    run bash -c 'printf "No orphan packages found.\n"'
  fi
}


# ── AUR ──────────────────────────────────────────────

install_aur() {
  local query package

  read -rp "Search AUR: " query
  [[ -z $query ]] && return

  package=$(
    paru -Ssaq "$query" |
      fzf \
        --reverse \
        --preview 'aur_preview {}'
  )

  [[ -n $package ]] &&
    run paru -S "${package#*/}"
}

uninstall_aur() {
  local package

  package=$(
    paru -Qmq |
      fzf \
        --reverse \
        --preview 'paru -Qi {}'
  )

  [[ -n $package ]] &&
    run paru -Rns "$package"
}

update_aur() {
  run paru -Sua
}

cleanup_aur() {
  run paru -Sc
}


# ── Flatpak ──────────────────────────────────────────

install_flatpak() {
  local package

  package=$(
    flatpak search --columns=application,name "" |
      fzf --reverse
  )

  package=$(awk '{print $1}' <<< "$package")

  [[ -n $package ]] &&
    run flatpak install "$package"
}

uninstall_flatpak() {
  local package

  package=$(
    flatpak list --app --columns=application,name |
      fzf --reverse
  )

  package=$(awk '{print $1}' <<< "$package")

  [[ -n $package ]] &&
    run flatpak uninstall "$package"
}

update_flatpak() {
  run flatpak update
}

cleanup_flatpak() {
  run flatpak uninstall --unused
}


# ── All ──────────────────────────────────────────────

update_all() {
  run bash -c '
    sudo pacman -Syu &&
    paru -Sua &&
    flatpak update
  '
}

cleanup_all() {
  run bash -c '
    orphans=$(pacman -Qdtq)

    if [[ -n $orphans ]]; then
      sudo pacman -Rns $orphans
    else
      echo "No orphan packages."
    fi

    paru -Sc
    flatpak uninstall --unused
  '
}


# ── Menus ────────────────────────────────────────────

declare -A actions=(
  ["$ICON_INSTALL Install package"]="install"
  ["$ICON_UNINSTALL Uninstall package"]="uninstall"
  ["$ICON_UPDATE Update"]="update"
  ["$ICON_CLEAN Clean up"]="cleanup"
)

declare -A managers=(
  ["$TAG_PACMAN Pacman"]="pacman"
  ["$TAG_AUR AUR"]="aur"
  ["$TAG_FLATPAK Flatpak"]="flatpak"
)


# ── Main loop ────────────────────────────────────────

while :; do
  clear

  selected=$(pick "${!actions[@]}")
  [[ -z $selected ]] && exit

  action=${actions[$selected]}

  menu=(
    "$TAG_PACMAN Pacman"
    "$TAG_AUR AUR"
    "$TAG_FLATPAK Flatpak"
  )

  [[ $action == update || $action == cleanup ]] &&
    menu+=("$action all")

  selected=$(pick "${menu[@]}")
  [[ -z $selected ]] && continue

  manager=${managers[$selected]:-all}

  case "$manager:$action" in
    pacman:install)    install_pacman ;;
    pacman:uninstall)  uninstall_pacman ;;
    pacman:update)     update_pacman ;;
    pacman:cleanup)    cleanup_pacman ;;

    aur:install)       install_aur ;;
    aur:uninstall)     uninstall_aur ;;
    aur:update)        update_aur ;;
    aur:cleanup)       cleanup_aur ;;

    flatpak:install)   install_flatpak ;;
    flatpak:uninstall) uninstall_flatpak ;;
    flatpak:update)    update_flatpak ;;
    flatpak:cleanup)   cleanup_flatpak ;;

    all:update)        update_all ;;
    all:cleanup)       cleanup_all ;;
  esac
done
