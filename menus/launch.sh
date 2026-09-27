

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec foot --app-id=fzf-menu-$1 -e "$SCRIPT_DIR/$1"
