#!/usr/bin/env bash
# Thumbnails live in tmpfs so copied images aren't persisted on disk
thumbs="${XDG_RUNTIME_DIR:-/tmp}/cliphist-thumbs"
mkdir -p "$thumbs"

menu="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/menu.sh"

cliphist list | while IFS=$'\t' read -r id preview; do
  if [[ "$preview" =~ ^\[\[\ binary\ data\ .*(png|jpg|jpeg|bmp|gif|webp) ]]; then
    f="$thumbs/$id.${BASH_REMATCH[1]}"
    [[ -f "$f" ]] || cliphist decode "$id" > "$f"
    printf '%s\t%s\0icon\x1f%s\n' "$id" "$preview" "$f"
  else
    printf '%s\t%s\n' "$id" "$preview"
  fi
done | "$menu" -p Clipboard -w 60 -l 5 -i 64 | cliphist decode | wl-copy
