#!/usr/bin/env bash

set -u

TAG_PACMAN="󰮯"
TAG_AUR="󰊢"
TAG_FLATPAK="󰏗"

ICON_INSTALL="󰐕"
ICON_UNINSTALL="󰆴"
ICON_UPDATE="󰚰"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "software: missing required dependency '$1'" >&2
    exit 1
  }
}

need fzf
need foot
need pacman

run_in_terminal() {
  foot --hold bash -c '
    "$@"
    status=$?
    stty sane 2>/dev/null
    exit "$status"
  ' bash "$@"
}

preview_package() {
  local selection="$1"
  local source pkg

  source=$(cut -d $'\037' -f2 <<<"$selection")
  pkg=$(cut -d $'\037' -f3 <<<"$selection")

  [ -n "$source" ] || return
  [ -n "$pkg" ] || return

  case "$source" in
    pacman)
      pacman -Si -- "$pkg" 2>/dev/null ||
        pacman -Qi -- "$pkg" 2>/dev/null
      ;;

    aur)
      if command -v paru >/dev/null 2>&1; then
        paru -Si -- "$pkg" 2>/dev/null ||
          pacman -Qi -- "$pkg" 2>/dev/null
      else
        pacman -Qi -- "$pkg" 2>/dev/null
      fi
      ;;

    flatpak)
      flatpak info "$pkg" 2>/dev/null
      ;;
  esac
}

fzf_menu() {
  fzf \
    --height=100% \
    --layout=reverse \
    --prompt="$1" \
    --no-multi \
    --delimiter=$'\037' \
    --with-nth=1 \
    --preview='
      selection="$FZF_CURRENT_ITEM"

      source=$(printf "%s" "$selection" | cut -d "$(printf "\037")" -f2)
      pkg=$(printf "%s" "$selection" | cut -d "$(printf "\037")" -f3)

      case "$source" in
        pacman)
          pacman -Si -- "$pkg" 2>/dev/null ||
            pacman -Qi -- "$pkg" 2>/dev/null
          ;;

        aur)
          if command -v paru >/dev/null 2>&1; then
            paru -Si -- "$pkg" 2>/dev/null ||
              pacman -Qi -- "$pkg" 2>/dev/null
          else
            pacman -Qi -- "$pkg" 2>/dev/null
          fi
          ;;

        flatpak)
          flatpak info "$pkg" 2>/dev/null
          ;;

        *)
          printf "Source: %s\nPackage: %s\n" "$source" "$pkg"
          ;;
      esac
    ' \
    --preview-window='right,50%,wrap'
}

list_pacman_installed() {
  pacman -Qqn |
    while IFS= read -r pkg; do
      printf '%s  %s\037pacman\037%s\n' \
        "$TAG_PACMAN" "$pkg" "$pkg"
    done
}

list_aur_installed() {
  pacman -Qqm |
    while IFS= read -r pkg; do
      printf '%s  %s\037aur\037%s\n' \
        "$TAG_AUR" "$pkg" "$pkg"
    done
}

list_flatpak_installed() {
  command -v flatpak >/dev/null 2>&1 || return

  flatpak list \
    --app \
    --columns=application,name \
    2>/dev/null |
    while IFS=$'\t' read -r id name; do
      [ -n "$id" ] || continue

      printf '%s  %s\037flatpak\037%s\n' \
        "$TAG_FLATPAK" "$name" "$id"
    done
}

list_installed_all() {
  list_pacman_installed
  list_aur_installed
  list_flatpak_installed
}

list_pacman_available() {
  pacman -Slq 2>/dev/null |
    while IFS= read -r pkg; do
      printf '%s  %s\037pacman\037%s\n' \
        "$TAG_PACMAN" "$pkg" "$pkg"
    done
}

list_aur_available() {
  command -v paru >/dev/null 2>&1 || return

  paru -Ss 2>/dev/null |
    awk '
      /^[^[:space:]]+\/[^[:space:]]+ / {
        split($1, a, "/")
        if (a[1] == "aur")
          print a[2]
      }
    ' |
    while IFS= read -r pkg; do
      [ -n "$pkg" ] || continue

      printf '%s  %s\037aur\037%s\n' \
        "$TAG_AUR" "$pkg" "$pkg"
    done
}

list_flatpak_available() {
  command -v flatpak >/dev/null 2>&1 || return

  flatpak remote-ls flathub \
    --app \
    --columns=application,name \
    2>/dev/null |
    while IFS=$'\t' read -r id name; do
      [ -n "$id" ] || continue

      printf '%s  %s\037flatpak\037%s\n' \
        "$TAG_FLATPAK" "$name" "$id"
    done
}

list_available_all() {
  list_pacman_available
  list_aur_available
  list_flatpak_available
}

install_package() {
  local source="$1"
  local pkg="$2"

  case "$source" in
    pacman)
      run_in_terminal sudo pacman -S -- "$pkg"
      ;;

    aur)
      run_in_terminal paru -S -- "$pkg"
      ;;

    flatpak)
      run_in_terminal flatpak install -y flathub -- "$pkg"
      ;;
  esac
}

remove_package() {
  local source="$1"
  local pkg="$2"

  case "$source" in
    pacman)
      run_in_terminal sudo pacman -Rns -- "$pkg"
      ;;

    aur)
      run_in_terminal sudo pacman -Rns -- "$pkg"
      ;;

    flatpak)
      run_in_terminal flatpak uninstall -y -- "$pkg"
      ;;
  esac
}

update_packages() {
  local sys_cmd

  if command -v paru >/dev/null 2>&1; then
    sys_cmd="paru -Syu"
  else
    sys_cmd="sudo pacman -Syu"
  fi

  if command -v flatpak >/dev/null 2>&1; then
    run_in_terminal bash -c "$sys_cmd && flatpak update -y"
  else
    run_in_terminal bash -c "$sys_cmd"
  fi
}

parse_selection() {
  SOURCE=$(cut -d $'\037' -f2 <<<"$1")
  PKG=$(cut -d $'\037' -f3 <<<"$1")
}

pick() {
  sort -u -t $'\037' -k1,1 |
    fzf_menu "$1"
}

manager_menu() {
  printf '%s\n' \
    '󰮯  All' \
    '󰮯  Pacman' \
    '󰊢  AUR' \
    '󰏗  Flatpak'
}

get_installed_lister() {
  case "$1" in
    All)
      echo list_installed_all
      ;;
    Pacman)
      echo list_pacman_installed
      ;;
    AUR)
      echo list_aur_installed
      ;;
    Flatpak)
      echo list_flatpak_installed
      ;;
  esac
}

browse_installed() {
  local manager="$1"
  local lister selection status

  lister=$(get_installed_lister "$manager")
  [ -n "$lister" ] || return 0

  selection=$(
    "$lister" |
      pick "$manager > "
  )
  status=$?

  [ "$status" -eq 130 ] && return 0
  [ -n "$selection" ] || return 0

  local SOURCE PKG
  parse_selection "$selection"

  remove_package "$SOURCE" "$PKG"
}

browse_install() {
  local manager="$1"
  local selection status
  local SOURCE PKG

  case "$manager" in
    All)
      selection=$(
        list_available_all |
          pick "Install > "
      )
      ;;

    Pacman)
      selection=$(
        list_pacman_available |
          pick "Pacman > "
      )
      ;;

    AUR)
      selection=$(
        list_aur_available |
          pick "AUR > "
      )
      ;;

    Flatpak)
      selection=$(
        list_flatpak_available |
          pick "Flatpak > "
      )
      ;;

    *)
      return 0
      ;;
  esac

  status=$?

  [ "$status" -eq 130 ] && return 0
  [ -n "$selection" ] || return 0

  parse_selection "$selection"
  install_package "$SOURCE" "$PKG"
}

browse_uninstall() {
  local manager="$1"
  local lister selection status

  lister=$(get_installed_lister "$manager")
  [ -n "$lister" ] || return 0

  selection=$(
    "$lister" |
      pick "$manager > "
  )
  status=$?

  [ "$status" -eq 130 ] && return 0
  [ -n "$selection" ] || return 0

  local SOURCE PKG
  parse_selection "$selection"

  remove_package "$SOURCE" "$PKG"
}

select_manager() {
  local action="$1"
  local manager status

  while true; do
    manager=$(
      manager_menu |
        fzf \
          --height=100% \
          --layout=reverse \
          --prompt="$action > " \
          --no-multi
    )
    status=$?

    [ "$status" -eq 130 ] && return 0
    [ -n "$manager" ] || return 0

    manager=$(sed -E 's/^.*  //' <<<"$manager")

    case "$action:$manager" in
      Installed:*)
        browse_installed "$manager"
        ;;

      Install:*)
        browse_install "$manager"
        ;;

      Uninstall:*)
        browse_uninstall "$manager"
        ;;
    esac
  done
}

main() {
  local mode status

  while true; do
    mode=$(
      printf '%s\n' \
        "$TAG_PACMAN  Installed" \
        "$ICON_UPDATE  Update" \
        "$ICON_INSTALL  Install" \
        "$ICON_UNINSTALL  Uninstall" |
        fzf \
          --height=100% \
          --layout=reverse \
          --prompt='Software > ' \
          --no-multi
    )
    status=$?

    [ "$status" -eq 130 ] && exit 0
    [ -n "$mode" ] || exit 0

    case "$mode" in
      *Installed)
        select_manager Installed
        ;;

      *Update)
        update_packages
        ;;

      *Install)
        select_manager Install
        ;;

      *Uninstall)
        select_manager Uninstall
        ;;
    esac
  done
}

main
