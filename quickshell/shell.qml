//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import "panels"

PanelWindow {
  id: root

  WallpaperSwitcher {}

  anchors { bottom: true; left: true; right: true }
  implicitHeight: 28
  exclusiveZone: 28
  color: "#09090b"

  readonly property color fg: "#e4e4e7"
  readonly property color dim: "#52525b"
  readonly property color red: "#f87171"
  readonly property color hover: "#27272a"
  readonly property string ff: "JetBrainsMono Nerd Font"

  // one poll
  property var l: Array(10).fill("")
  readonly property bool muted: l[0].includes("MUTED")
  readonly property int vol: Math.round(parseFloat(l[0].split(" ")[1]) * 100) || 0
  readonly property int bri: parseInt(l[1]) || 0
  readonly property int bat: parseInt(l[2]) || 0
  readonly property bool chg: l[2].includes("Charging")
  readonly property string net: l[3].slice(l[3].indexOf(":") + 1)
  readonly property bool eth: l[3].startsWith("ethernet")
  readonly property int sig: parseInt(l[4]) || 0
  readonly property int bt: parseInt(l[5]) || 0
  readonly property bool caf: l[6] === "1"
  readonly property bool mic: l[7].includes("MUTED")
  readonly property bool share: l[8] === "1"
  readonly property string cal: l[9]
  readonly property string calHtml: {
    const re = new RegExp("(^|\\s)(" + clock.date.getDate() + ")(?=\\s|$)")
    return cal.split(":")
      .map((s, i) => (i < 2 ? s : s.replace(re, "$1\u0001$2\u0002")).replace(/ /g, "&nbsp;"))
      .join("<br>")
      .replace("\u0001", '<b><font color="#f87171">').replace("\u0002", "</font></b>")
  }

  function run(...a) { Quickshell.execDetached(a); poll.running = true }

  Process {
    id: poll
    command: ["bash", "-c", `
      echo "$(wpctl get-volume @DEFAULT_AUDIO_SINK@)"
      echo "$(brightnessctl -m | cut -d, -f4)"
      echo $(cat /sys/class/power_supply/BAT*/{capacity,status} | head -2)
      echo "$(nmcli -t -f TYPE,NAME connection show --active | grep -E '^(802-11-wireless|ethernet)' | head -1)"
      echo "$(nmcli -t -f IN-USE,SIGNAL dev wifi | sed -n 's/^[*]://p')"
      bluetoothctl show | grep -q 'Powered: yes' && { bluetoothctl devices Connected | grep -q . && echo 2 || echo 1; } || echo 0
      pgrep -x hypridle >/dev/null && echo 0 || echo 1
      echo "$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)"
      pw-cli list-objects Node | grep -Fq xdg-desktop-portal-hyprland && echo 1 || echo 0
      cal -m | tr '\n' ':' | sed 's/:$//'
    `]
    stdout: StdioCollector { onStreamFinished: root.l = this.text.split("\n") }
  }

  Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: poll.running = true }
  SystemClock { id: clock; precision: SystemClock.Minutes }

  // Icon/text button with tooltip
  component Btn: Item {
    id: b
    property string text
    property string tip
    property color col: root.fg
    property int size: 15
    signal clicked

    implicitWidth: t.implicitWidth + 12
    implicitHeight: 28

    Rectangle { anchors.fill: parent; color: m.containsMouse ? root.hover : "transparent" }
    Text { id: t; anchors.centerIn: parent; text: b.text; color: b.col; font.family: root.ff; font.pixelSize: b.size }
    MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; onClicked: b.clicked() }

    PopupWindow {
      visible: m.containsMouse && b.tip !== ""
      anchor.item: b
      anchor.edges: Edges.Top
      anchor.gravity: Edges.Top
      implicitWidth: tt.implicitWidth + 14
      implicitHeight: tt.implicitHeight + 8
      color: "#18181b"
      Text { id: tt; anchors.centerIn: parent; text: b.tip; color: root.fg; font.family: root.ff; font.pixelSize: 11 }
    }
  }

  // Left: workspaces
  Row {
    anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
    Repeater {
      model: 9
      Btn {
        readonly property int id: index + 1
        text: id
        size: 12
        tip: "Workspace " + id
        col: Hyprland.focusedWorkspace?.id === id ? root.red
           : Hyprland.workspaces.values.some(w => w.id === id) ? root.fg : root.dim
        onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })")      }
    }
  }

  // Center:
  Row {
    anchors.centerIn: parent
    Btn {
      text: root.caf ? "󰅶" : "󰾪"
      col: root.caf ? root.red : root.fg
      tip: "Caffeine " + (root.caf ? "enabled" : "disabled")
      onClicked: root.run("bash", "-c", "pgrep -x hypridle && pkill -x hypridle || hypridle")
    }
    Btn {
      text: root.mic ? "󰍭" : "󰍬"
      col: root.mic ? root.red : root.fg
      tip: "Microphone " + (root.mic ? "muted" : "enabled")
      onClicked: root.run("wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle")
    }
    Btn {
      size: 12
      text: Qt.formatDateTime(clock.date, "ddd d MMM  h:mm AP")
      tip: root.calHtml
    }
    Btn { visible: root.share; text: "󰍹"; col: root.red; tip: "Screen sharing active" }
  }

  // Right: tray + status (battery last)
  Row {
    anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }

    Row {
      spacing: 5
      rightPadding: 8
      Repeater {
        model: SystemTray.items
        Item {
          id: ti
          width: 16; height: 28
          Image { anchors.centerIn: parent; width: 16; height: 16; source: modelData.icon }
          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: e => {
              if (e.button === Qt.LeftButton) modelData.activate()
              else if (e.button === Qt.MiddleButton) modelData.secondaryActivate()
              else { const p = root.itemPosition(ti); modelData.display(root, Math.round(p.x + 8), Math.round(p.y + ti.height)) }
            }
          }
        }
      }
    }

    Btn {  // volume
      visible: false
      text: root.muted ? "󰝟" : ["󰕿", "󰖀", "󰕾"][Math.min(2, root.vol / 33 | 0)]
      col: root.muted ? root.red : root.fg
      tip: root.muted ? "Volume muted" : "Volume: " + root.vol + "%"
      onClicked: Quickshell.execDetached(["pwvucontrol"])
    }
    Btn {  // brightness
      visible: false
      text: ["󰃚", "󰃛", "󰃜", "󰃝", "󰃞", "󰃟", "󰃠"][Math.min(6, root.bri / 15 | 0)]
      tip: "Brightness: " + root.bri + "%"
    }
    Btn {  // clipboard
      text: "󰅇"
      tip: "Clipboard history"
      onClicked: root.run("bash", "-c", "~/dotfiles/menus/clipboard.sh")
    }
    Btn {  // network
      text: !root.net ? "󰤭" : root.eth ? "󰈀" : ["󰤟", "󰤢", "󰤥", "󰤨"][Math.min(3, root.sig / 25 | 0)]
      col: root.net ? root.fg : root.dim
      tip: root.net ? "Network: " + root.net : "Network disconnected"
      onClicked: Quickshell.execDetached(["foot", "--app-id=nmtui", "-e", "nmtui"])
    }
    Btn {  // bluetooth
      text: ["󰂲", "󰂯", "󰂱"][root.bt]
      col: root.bt ? root.fg : root.dim
      tip: "Bluetooth: " + ["off", "on", "connected"][root.bt]
      onClicked: Quickshell.execDetached(["foot", "--app-id=bluetui", "-e", "bluetui"])
    }
    Btn {  // battery
      text: root.chg
        ? ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"][Math.min(9, root.bat / 10 | 0)]
        : ["󰁹", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂"][Math.max(1, Math.round(root.bat / 10)) % 10]
      col: root.bat <= 15 && !root.chg ? root.red : root.fg
      tip: "Battery: " + root.bat + "%" + (root.chg ? " (charging)" : "")
    }
  }
}

