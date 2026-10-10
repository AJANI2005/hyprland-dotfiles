username="Docker"
password="admin"
ip="localhost:3389"
echo "Starting Dockurr Windows..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


docker-compose -f "$SCRIPT_DIR/windows.yml" up -d
sleep 5

xfreerdp3 /u:"$username" /p:"$password" /v:"$ip" \
  /dynamic-resolution \
  /clipboard \
  /gfx:avc444 \
  /audio-mode:0 \
  /microphone


read -rp "Keep Windows container running? [y/N] " answer

if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Leaving container running."
else
    docker-compose -f "$SCRIPT_DIR/windows.yml" down
fi
