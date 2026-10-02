#!/usr/bin/env bash

shopt -s nullglob

cache="${XDG_CACHE_HOME:-$HOME/.cache}/app-launcher"
term="${TERMINAL:-foot}"
dirs=("$HOME/.local/share/applications" /usr/share/applications)

build() {
    declare -A seen
    local file dir name cmd

    for dir in "${dirs[@]}"; do
        for file in "$dir"/*.desktop; do
            [[ -f $file ]] || continue
            grep -q '^NoDisplay=true' "$file" && continue

            name=$(sed -n 's/^Name=//p' "$file" | head -1)
            cmd=$(sed -n 's/^Exec=//p' "$file" | head -1)

            [[ $name && $cmd ]] || continue
            [[ ${seen[$name]} ]] && continue
            seen["$name"]=1

            cmd=${cmd//\%[fFuUdDnNickvm]/}
            grep -q '^Terminal=true' "$file" && cmd="$term -e $cmd"

            printf '%s\t%s\n' "$name" "$cmd"
        done
    done
}

stale=0
[[ -f $cache ]] || stale=1

for dir in "${dirs[@]}"; do
    [[ $dir -nt $cache ]] && stale=1
done

if ((stale)); then
    mkdir -p "${cache%/*}"
    build | sort -f >"$cache"
fi

choice=$(
    cut -f1 "$cache" |
    fzf \
        --height=100% \
        --layout=reverse \
        --prompt='Apps: ' \
        --info=hidden
) || exit

cmd=$(awk -F '\t' -v name="$choice" '$1 == name {print $2; exit}' "$cache")

[[ $cmd ]] || exit

setsid -f sh -c "$cmd" >/dev/null 2>&1
