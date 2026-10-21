
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
  id: root

  property int volume: 0
  property int brightness: 0
  property bool muted: false
  property string mode: "volume"
  property string ff: "JetBrainsMono Nerd Font"

  function showVolume(line) {
    const match = line.match(/Volume: ([0-9.]+)/)
    if (!match) return

    const nextVolume = Math.round(Number(match[1]) * 100)
    const nextMuted = line.includes("[MUTED]")

    if (nextVolume === volume && nextMuted === muted) return

    volume = nextVolume
    muted = nextMuted
    mode = "volume"
    osd.visible = true
    hideTimer.restart()
  }

  function showBrightness(value) {
    const next = parseInt(value)
    if (isNaN(next)) return
    if (next === brightness) return

    brightness = next
    mode = "brightness"
    osd.visible = true
    hideTimer.restart()
  }

  Process {
    id: volumeEvents
    command: ["bash", "-c", `
      wpctl get-volume @DEFAULT_AUDIO_SINK@
      pactl subscribe | while read -r event; do
        case "$event" in
          *"on sink "*|*"on server "*)
            wpctl get-volume @DEFAULT_AUDIO_SINK@
            ;;
        esac
      done
    `]
    running: true

    stdout: SplitParser {
      onRead: data => root.showVolume(data)
    }
  }

  Process {
    id: brightnessPoll
    command: ["bash", "-c", `
      brightnessctl -m | cut -d, -f4 | tr -d '%'
    `]

    stdout: StdioCollector {
      onStreamFinished: root.showBrightness(this.text.trim())
    }
  }

  Timer {
    interval: 200
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: brightnessPoll.running = true
  }

  Timer {
    id: hideTimer
    interval: 1400
    onTriggered: osd.visible = false
  }

  PanelWindow {
    id: osd

    anchors {
      bottom: true
    }

    margins {
      bottom: 100
    }

    implicitWidth: content.implicitWidth + 32
    implicitHeight: 52
    color: "transparent"
    exclusiveZone: 0
    visible: false

    Rectangle {
      anchors.fill: parent
      color: "#09090b"
      radius: 8
      border.width: 1
      border.color: "#27272a"
    }

    Row {
      id: content
      anchors.centerIn: parent
      spacing: 12

      Text {
        anchors.verticalCenter: parent.verticalCenter

        text: root.mode === "volume"
          ? (root.muted ? "󰝟" :
             root.volume < 35 ? "󰕿" :
             root.volume < 70 ? "󰖀" : "󰕾")
          : (root.brightness < 35 ? "󰃞" :
             root.brightness < 70 ? "󰃟" : "󰃠")

        color: root.mode === "volume" && root.muted
          ? "#f87171" : "#ffffff"

        font.family: root.ff
        font.pixelSize: 22
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter

        text: root.mode === "volume"
          ? (root.muted ? "Muted" : root.volume + "%")
          : root.brightness + "%"

        color: "#ffffff"
        font.family: root.ff
        font.pixelSize: 16
        font.weight: Font.Medium
      }
    }
  }
}

