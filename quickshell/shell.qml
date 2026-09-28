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

    WallpaperSwitcher{}

    anchors {
        bottom: true
        left: true
        right: true
    }

    implicitHeight: 28
    color: "#09090b"
    exclusiveZone: 28

    property string volume: "VOL 0%"
    property string bright: "BRT 0%"
    property string battery: "BAT 0%"

    Process {
        id: volumeProc

        command: [
            "bash", "-c",
            "wpctl get-volume @DEFAULT_AUDIO_SINK@"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let m = this.text.match(
                    /Volume:\s+([0-9.]+)/
                )

                if (m) {
                    root.volume =
                        "VOL " +
                        Math.round(m[1] * 100) +
                        "%"
                }
            }
        }
    }

    Process {
        id: brightProc

        command: [
            "bash", "-c",
            "brightnessctl -m | cut -d, -f4"
        ]

        stdout: StdioCollector {
            onStreamFinished:
                root.bright = "BRT " + this.text.trim()
        }
    }

    Process {
        id: batteryProc

        command: [
            "bash", "-c",
            "upower -i $(upower -e | grep 'BAT') | grep -E 'percentage:' | awk '{print $2}'"
        ]

        stdout: StdioCollector {
            onStreamFinished:
                root.battery = "BAT " + this.text.trim()
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            volumeProc.running = true
            brightProc.running = true
            batteryProc.running = true
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 12

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
                        ? "#ef4444"
                        : ws
                            ? "#a1a1aa"
                            : "#3f3f46"

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

        Text {
            Layout.fillWidth: true

            text: Hyprland.focusedToplevel?.title ?? ""
            color: "#71717a"

            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        Row {
            spacing: 12

            Text {
                text: root.volume
                color: "#a1a1aa"

                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
            }

            Text {
                text: root.bright
                color: "#a1a1aa"

                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
            }

            Text {
                text: root.battery
                color: "#a1a1aa"

                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
            }

            Row {
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
                            fillMode: Image.PreserveAspectFit
                        }

                        PopupWindow {
                            id: trayMenuWindow

                            implicitWidth: 1
                            implicitHeight: 1

                            color: "transparent"

                            anchor.item: trayItem
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
                                } else if (
                                    mouse.button === Qt.MiddleButton
                                ) {
                                    modelData.secondaryActivate()
                                } else if (
                                    mouse.button === Qt.RightButton
                                ) {
                                    modelData.display(
                                        root,
                                        root.width,
                                        root.y
                                    )
                                }
                            }
                        }
                    }
                }
            }

            SystemClock {
                id: systemClock
                precision: SystemClock.Minutes
            }

            Text {
                text: Qt.formatDateTime(
                    systemClock.date,
                    "ddd d MMM h:mm AP"
                  )

                color: "#f4f4f5"

                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
            }
        }
    }
}
