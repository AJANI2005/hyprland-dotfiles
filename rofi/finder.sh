#!/usr/bin/env bash
# System-wide file finder for rofi, powered by plocate.
#
# Install: save as ~/.local/share/rofi/finder.sh and chmod +x it
# Use:
#   rofi -show find -modi "find:$HOME/.local/share/rofi/finder.sh" \
#        -kb-custom-1 "Alt+Return" -kb-custom-2 "Alt+c"
#
# Type words + Enter to search, then pick a result:
#   Enter = open | Alt+Enter = open folder | Alt+c = copy path
#
# ROFI_RETV: 0 = first launch, 1 = row selected, 2 = typed text + Enter,
#            10 = Alt+Enter, 11 = Alt+c

LIMIT=2000   # max results shown
SETUP_ROW="⚙ Run setup (install plocate + build index)"

# ---------- helpers ----------

has() { command -v "$1" >/dev/null; }

# plocate installed and index usable
ready() { has plocate && plocate -l 1 -- / >/dev/null 2>&1; }

# Open with default app, detached so rofi can exit
open() { setsid -f xdg-open "$1" >/dev/null 2>&1; }

# Copy to clipboard (Wayland, then X11)
copy() {
  if has wl-copy; then printf '%s' "$1" | wl-copy
  else printf '%s' "$1" | xclip -selection clipboard
  fi
}

# Prompt, hotkeys, and message bar
header() {
  printf '\0prompt\x1fFind\n'
  printf '\0use-hot-keys\x1ftrue\n'
  printf '\0message\x1f%s\n' "$1"
}

# Unselectable row; keeps rofi open when there are no results
placeholder() { printf '%s\0nonselectable\x1ftrue\n' "$1"; }

# ---------- one-time setup ----------

# Runs in foot so sudo can prompt for a password
do_setup() {
  if ! has plocate; then
    echo "Installing plocate..."
    if   has pacman;       then sudo pacman -S --needed --noconfirm plocate
    elif has apt;          then sudo apt install -y plocate
    elif has dnf;          then sudo dnf install -y plocate
    elif has zypper;       then sudo zypper install -y plocate
    elif has xbps-install; then sudo xbps-install -y plocate
    elif has apk;          then sudo apk add plocate
    else echo "Unknown package manager: install plocate manually."; return 1
    fi || { echo "Install failed."; return 1; }
  fi

  echo "Building file index (may take a minute)..."
  sudo updatedb || return 1
  sudo systemctl enable --now plocate-updatedb.timer 2>/dev/null  # daily refresh
  echo "Done. Reopen the finder."
}

# Delay lets rofi release the keyboard before foot opens
run_setup() {
  has foot || return 1
  local cmd="$(declare -f has do_setup); do_setup; echo; read -rp 'Press Enter to close '"
  setsid -f bash -c 'sleep 0.7; exec foot bash -c "$1"' _ "$cmd" >/dev/null 2>&1
}

# ---------- handle a selected row ----------

case $ROFI_RETV in
  1|10|11)
    [[ $1 == "$SETUP_ROW" ]] && { run_setup; exit 0; }

    # Real path: act on it and close. Anything else falls through
    # and redisplays, so rofi stays open.
    if [[ -e $1 ]]; then
      case $ROFI_RETV in
        1)  open "$1" ;;
        10) open "$(dirname "$1")" ;;
        11) copy "$1" ;;
      esac
      exit 0
    fi
    ;;
esac

# ---------- not set up yet ----------

if ! ready; then
  header "Index not ready. Select the row below to set it up (opens foot for sudo)."
  printf '%s\n' "$SETUP_ROW"
  exit 0
fi

# ---------- search ----------
# "Search again" row; meta makes it match whatever is typed
search_row() { printf '!!\n' "$SEARCH_ROW" "$1"; }
# -i ignore case, -A all words in any order, -e skip deleted, -l limit
if [[ $ROFI_RETV == 2 && -n $1 ]]; then
  read -ra words <<< "$1"
  results=$(plocate -i -A -e -l "$LIMIT" -- "${words[@]}")

  if [[ -z $results ]]; then
    header "No matches for: $1  (new files appear after 'sudo updatedb')"
  else
    header "$(wc -l <<< "$results") results for: $1  |  Enter: open  Alt+Enter: folder  Alt+c: copy path  |  Up: search again"
    printf '%s\n' "$results"
  fi
  search_row "$1"
  exit 0
fi

# ---------- first launch / bad selection ----------

header "Type words to search every file on the system, then press Enter"
placeholder "Type a search and press Enter."
