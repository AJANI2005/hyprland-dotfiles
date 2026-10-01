//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import "panels"

PanelWindow {
  id: root

  WallpaperSwitcher {}

  anchors {
    bottom: true
    left: true
    right: true
  }

  implicitHeight: 28
  color: "#09090b"
  exclusiveZone: 28

  // Colors
  property color moduleBg: "#18181b"
  property color labelBg: "#27272a"
  property color hoverBg: "#303036"

  property color labelColor: "#a1a1aa"
  property color textColor: "#e4e4e7"
  property color mutedColor: "#71717a"

  property color activeColor: "#f87171"
  property color inactiveColor: "#52525b"

  // State
  property string volume: "0%"
  property string bright: "0%"
  property string battery: "0%"
  property string network: "OFF"
  property string bluetooth: "OFF"

  property bool caffeine: false
  property bool micMuted: false
  property bool screenSharing: false

  // ============================================================
  // Reusable module
  // ============================================================

  component Module: Item {
    id: module

    property string label
    property string value

    signal clicked()

    implicitWidth: content.width
    implicitHeight: 24

    Row {
      id: content

      height: 24
      spacing: 1

      Rectangle {
        width: labelText.implicitWidth + 10
        height: 24
        color: root.labelBg

        Text {
          id: labelText

          anchors.centerIn: parent
          text: module.label
          color: root.labelColor

          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 12
          font.bold: true
        }
      }

      Rectangle {
        width: valueText.implicitWidth + 10
        height: 24
        color: root.moduleBg

        Text {
          id: valueText

          anchors.centerIn: parent
          text: module.value
          color: root.textColor

          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 12
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor

      onClicked:
        module.clicked()
    }
  }

  // ============================================================
  // Caffeine
  // ============================================================

  component Caffeine: Rectangle {
    id: caffeineModule

    width: 28
    height: 24

    color: "transparent"

    Text {
      anchors.centerIn: parent

      text: "󰅶"

      color: root.caffeine
        ? root.textColor
        : root.activeColor

      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 15
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor

      onClicked:
        caffeineToggle.running = true
    }
  }

  // ============================================================
  // Microphone mute
  // ============================================================

  component MicMute: Rectangle {
    id: micModule

    width: 28
    height: 24

    color: "transparent"

    Text {
      anchors.centerIn: parent

      text: root.micMuted
        ? "󰍭"
        : "󰍬"

      color: root.micMuted
        ? root.activeColor
        : root.textColor

      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 15
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor

      onClicked:
        micMuteToggle.running = true
    }
  }

  // ============================================================
  // Screen sharing
  // ============================================================

  component ScreenShare: Rectangle {
    id: screenShareModule

    visible: root.screenSharing

    width: root.screenSharing ? 28 : 0
    height: 24

    color: "transparent"

    Text {
      anchors.centerIn: parent

      text: "󰍹"
      color: root.activeColor

      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 15
    }
  }

  // ============================================================
  // Volume
  // ============================================================

  Process {
    id: volumeProc

    command: [
      "bash",
      "-c",
      "wpctl get-volume @DEFAULT_AUDIO_SINK@"
    ]

    stdout: StdioCollector {
      onStreamFinished: {
        let output = this.text.trim()

        if (output.includes("[MUTED]")) {
          root.volume = "MUTE"
          return
        }

        let match = output.match(/Volume:\s+([0-9.]+)/)

        if (match)
          root.volume =
            Math.round(match[1] * 100) + "%"
      }
    }
  }

  // ============================================================
  // Brightness
  // ============================================================

  Process {
    id: brightProc

    command: [
      "bash",
      "-c",
      "brightnessctl -m | cut -d, -f4"
    ]

    stdout: StdioCollector {
      onStreamFinished:
        root.bright = this.text.trim()
    }
  }

  // ============================================================
  // Battery
  // ============================================================

  Process {
    id: batteryProc

    command: [
      "bash",
      "-c",
      "upower -i $(upower -e | grep 'BAT') | " +
      "grep -E 'percentage:' | awk '{print $2}'"
    ]

    stdout: StdioCollector {
      onStreamFinished:
        root.battery = this.text.trim()
    }
  }

  // ============================================================
  // Network
  // ============================================================

  Process {
    id: networkProc

    command: [
      "bash",
      "-c",
      "nmcli -t -f NAME,TYPE connection show --active | " +
      "awk -F: '$2 == \"802-11-wireless\" || " +
      "$2 == \"ethernet\" {print $1; exit}'"
    ]

    stdout: StdioCollector {
      onStreamFinished: {
        let name = this.text.trim()

        root.network =
          name.length > 0
          ? name
          : "OFF"
      }
    }
  }

  // ============================================================
  // Bluetooth
  // ============================================================

  Process {
    id: bluetoothProc

    command: [
      "bash",
      "-c",
      "bluetoothctl show | " +
      "grep -q 'Powered: yes' && echo ON || echo OFF"
    ]

    stdout: StdioCollector {
      onStreamFinished:
        root.bluetooth = this.text.trim()
    }
  }

  // ============================================================
  // Microphone state
  // ============================================================

  Process {
    id: micState

    command: [
      "bash",
      "-c",
      "wpctl get-volume @DEFAULT_AUDIO_SOURCE@"
    ]

    stdout: StdioCollector {
      onStreamFinished:
        root.micMuted =
          this.text.includes("[MUTED]")
    }
  }

  // ============================================================
  // Screen sharing state
  // ============================================================

  Process {
    id: screenShareState

    command: [
      "bash",
      "-c",
      "pw-cli list-objects Node | " +
      "grep -Fq 'node.name = \"xdg-desktop-portal-hyprland\"' && " +
      "echo ON || echo OFF"
    ]

    stdout: StdioCollector {
      onStreamFinished:
        root.screenSharing =
          this.text.trim() === "ON"
    }
  }

  // ============================================================
  // Volume launcher
  // ============================================================

  Process {
    id: volumeLaunch

    command: [
      "pwvucontrol"
    ]
  }

  // ============================================================
  // Network launcher
  // ============================================================

  Process {
    id: networkLaunch

    command: [
      "foot",
      "--app-id=nmtui",
      "-e",
      "nmtui"
    ]
  }

  // ============================================================
  // Bluetooth launcher
  // ============================================================

  Process {
    id: bluetoothLaunch

    command: [
      "foot",
      "--app-id=bluetui",
      "-e",
      "bluetui"
    ]
  }

  // ============================================================
  // Caffeine toggle
  // ============================================================

  Process {
    id: caffeineToggle

    command: [
      "bash",
      "-c",
      "if pgrep -x hypridle >/dev/null; then " +
      "pkill -x hypridle; " +
      "else " +
      "hypridle >/dev/null 2>&1 & " +
      "fi"
    ]

    onExited:
      caffeineState.running = true
  }

  // ============================================================
  // Caffeine state
  // ============================================================

  Process {
    id: caffeineState

    command: [
      "bash",
      "-c",
      "pgrep -x hypridle >/dev/null && echo ON || echo OFF"
    ]

    stdout: StdioCollector {
      onStreamFinished:
        root.caffeine =
          this.text.trim() === "ON"
    }
  }

  // ============================================================
  // Microphone toggle
  // ============================================================

  Process {
    id: micMuteToggle

    command: [
      "wpctl",
      "set-mute",
      "@DEFAULT_AUDIO_SOURCE@",
      "toggle"
    ]

    onExited:
      micState.running = true
  }

  // ============================================================
  // Update everything
  // ============================================================

  Timer {
    interval: 1000
    running: true
    repeat: true

    onTriggered: {
      volumeProc.running = true
      brightProc.running = true
      batteryProc.running = true
      networkProc.running = true
      bluetoothProc.running = true
      caffeineState.running = true
      micState.running = true
      screenShareState.running = true
    }
  }

  Component.onCompleted: {
    volumeProc.running = true
    brightProc.running = true
    batteryProc.running = true
    networkProc.running = true
    bluetoothProc.running = true
    caffeineState.running = true
    micState.running = true
    screenShareState.running = true
  }

  // ============================================================
  // Clock
  // ============================================================

  SystemClock {
    id: systemClock

    precision: SystemClock.Minutes
  }

  // ============================================================
  // Main bar
  // ============================================================

  RowLayout {
    anchors.fill: parent

    anchors.leftMargin: 8
    anchors.rightMargin: 8

    spacing: 12

    // ----------------------------------------------------------
    // Workspaces - LEFT
    // ----------------------------------------------------------

    Row {
      spacing: 10

      Repeater {
        model: 9

        Text {
          property bool active:
            Hyprland.focusedWorkspace?.id === index + 1

          property var ws:
            Hyprland.workspaces.values.find(
              w => w.id === index + 1
            )

          text: index + 1

          color: active
            ? root.activeColor
            : ws
            ? root.labelColor
            : root.inactiveColor

          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 12
          font.bold: active

          MouseArea {
            anchors.fill: parent

            onClicked:
              Hyprland.dispatch(
                "workspace " + (index + 1)
              )
          }
        }
      }
    }

    // ----------------------------------------------------------
    // Window title - CENTER AREA
    // ----------------------------------------------------------

    Text {
      Layout.fillWidth: true

      text:
        Hyprland.focusedToplevel?.title ?? ""

      color: root.mutedColor

      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 12

      elide: Text.ElideRight
    }

    // ----------------------------------------------------------
    // Right side
    // ----------------------------------------------------------

    Row {
      spacing: 2

      // --------------------------------------------------------
      // System tray
      // --------------------------------------------------------

      Rectangle {
        width: trayContent.width + 12
        height: 24

        color: "transparent"

        Row {
          id: trayContent

          anchors.centerIn: parent
          spacing: 5

          Repeater {
            model: SystemTray.items

            delegate: Item {
              id: trayItem

              width: 16
              height: 16

              Image {
                anchors.fill: parent

                source: modelData.icon
                sourceSize: Qt.size(16, 16)

                fillMode:
                  Image.PreserveAspectFit
              }

              MouseArea {
                anchors.fill: parent

                acceptedButtons:
                  Qt.LeftButton |
                  Qt.MiddleButton |
                  Qt.RightButton

                onClicked: mouse => {
                  if (mouse.button === Qt.LeftButton) {
                    modelData.activate()
                  } else if (mouse.button === Qt.MiddleButton) {
                    modelData.secondaryActivate()
                  } else if (mouse.button === Qt.RightButton) {
                    let pos = root.itemPosition(trayItem)

                    modelData.display(
                      root,
                      Math.round(
                        pos.x + trayItem.width / 2
                      ),
                      Math.round(
                        pos.y + trayItem.height
                      )
                    )
                  }
                }
              }
            }
          }
        }
      }

      // --------------------------------------------------------
      // Volume
      // --------------------------------------------------------

      Module {
        label: "VOL"
        value: root.volume

        onClicked: {
          if (!volumeLaunch.running)
            volumeLaunch.running = true
        }
      }

      // --------------------------------------------------------
      // Brightness
      // --------------------------------------------------------

      Module {
        label: "BRT"
        value: root.bright
      }

      // --------------------------------------------------------
      // Battery
      // --------------------------------------------------------

      Module {
        label: "BAT"
        value: root.battery
      }

      // --------------------------------------------------------
      // Network
      // --------------------------------------------------------

      Module {
        label: "NET"
        value: root.network

        onClicked: {
          if (!networkLaunch.running)
            networkLaunch.running = true
        }
      }

      // --------------------------------------------------------
      // Bluetooth
      // --------------------------------------------------------

      Module {
        label: "BT"
        value: root.bluetooth

        onClicked: {
          if (!bluetoothLaunch.running)
            bluetoothLaunch.running = true
        }
      }

      // --------------------------------------------------------
      // Clock
      // --------------------------------------------------------

      Rectangle {
        width: clockText.width + 16
        height: 24

        color: root.moduleBg

        Text {
          id: clockText

          anchors.centerIn: parent

          text: Qt.formatDateTime(
            systemClock.date,
            "ddd d MMM h:mm AP"
          )

          color: root.textColor

          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 12
        }
      }
    }
  }

  // ============================================================
  // CENTERED TOGGLES
  // ============================================================

  Row {
    anchors.centerIn: parent

    spacing: 4

    Caffeine {}
    MicMute {}
    ScreenShare {}
  }
}

