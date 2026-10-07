#!/usr/bin/env bash
set -u

menu="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/menu.sh"
pick() { "$menu" -w 30 -p "$1"; }

run()  { foot --app-id=package-tui bash -c "$1; printf '\nPress any key to close...'; read -rsn1"; }
get()  { local ref="$1[$2]"; echo "${!ref}"; }

declare -A SEARCH=([pacman]='pacman -Ssq' [aur]='paru -Ssaq' [flatpak]='flatpak search --columns=application,name')
declare -A LIST=([pacman]='pacman -Qqe' [aur]='paru -Qmq' [flatpak]='flatpak list --app --columns=application')
declare -A INFO=([pacman]='pacman -Si' [aur]='paru -Si' [flatpak]='flatpak remote-info flathub')
declare -A QINFO=([pacman]='pacman -Qi' [aur]='paru -Qi' [flatpak]='flatpak info')
declare -A INSTALL=([pacman]='sudo pacman -S' [aur]='paru -S' [flatpak]='flatpak install')
declare -A REMOVE=([pacman]='sudo pacman -Rns' [aur]='paru -Rns' [flatpak]='flatpak uninstall')
declare -A UPDATE=([pacman]='sudo pacman -Syu' [aur]='paru -Sua' [flatpak]='flatpak update')
declare -A CLEANUP=(
  [pacman]='orphans=$(pacman -Qdtq); if [[ $orphans ]]; then sudo pacman -Rns $orphans; else echo "No orphan packages."; fi'
  [aur]='paru -Sc'
  [flatpak]='flatpak uninstall --unused'
)
declare -A INSTALLED=([pacman]='pacman -Qq' [aur]='pacman -Qqm' [flatpak]='flatpak list --app --columns=application')

# Prefix each search result with ✓ (installed) or ✗ (not installed)
mark() {
  awk -v inst="$(${INSTALLED[$1]})" '
    BEGIN { n = split(inst, a, "\n"); for (i = 1; i <= n; i++) seen[a[i]] = 1 }
    { print (($1 in seen) ? "✓ " : "✗ ") $0 }'
}

while :; do
  action=$(printf '%s\n' "󰐕 Install" "󰆴 Uninstall" "󰚰 Update" "󰩹 Clean up" | pick Action) || exit
  action=${action#* }; action=${action,,}; action=${action// /}

  options=("󰮯 Pacman" "󰊢 AUR" "󰏗 Flatpak")
  [[ $action == update || $action == cleanup ]] && options+=("󰋙 All")
  manager=$(printf '%s\n' "${options[@]}" | pick "${action^}") || continue
  manager=${manager#* }; manager=${manager,,}

  case $action in
    update|cleanup)
      if [[ $manager == all ]]; then
        command=; for each in pacman aur flatpak; do command+="${command:+; }$(get "${action^^}" $each)"; done
      else
        command=$(get "${action^^}" $manager)
      fi
      run "$command" ;;

    install)
      query=; [[ $manager == pacman ]] || { query=$(pick "Search $manager" </dev/null) && [[ $query ]] || continue; }
      package=$(${SEARCH[$manager]} "$query" | mark "$manager" | pick Install) || continue
      package=${package#* }                                  # drop the ✓/✗ marker
      package=${package#*/}; package=${package%%[[:space:]]*}
      run "$(get INFO $manager) $package; read -rp 'Install $package? [Y/n] ' reply; [[ \${reply,,} != n ]] && $(get INSTALL $manager) $package" ;;

    uninstall)
      package=$(${LIST[$manager]} | pick Uninstall) || continue
      package=${package%%[[:space:]]*}
      run "$(get QINFO $manager) $package; read -rp 'Remove $package? [y/N] ' reply; [[ \${reply,,} == y ]] && $(get REMOVE $manager) $package" ;;
  esac
done
