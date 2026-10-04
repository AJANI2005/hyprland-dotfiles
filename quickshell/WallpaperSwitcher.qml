// Wallpaper switcher: minimal carousel with folder support.
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
  id: root

  property bool open: false
  property var images: []
  property var folders: []
  property var folderImages: []
  property int currentDirIndex: 0
  property int selectedIndex: 0
  property string folderText: ""

  readonly property int radius: 3
  readonly property int previewWidth: 880
  readonly property int previewHeight: 620
  readonly property int sliceWidth: 70
  readonly property int sliceHeight: 380
  readonly property int sliceSpacing: -30
  readonly property int skewOffset: 28

  IpcHandler {
    target: "wallpapers"
    function toggle(): void { root.open = !root.open }
  }

  Process {
    id: listProc
    command: ["bash", "-c",
      "D=\"$HOME/Wallpapers\"; [ -d \"$D\" ] || exit 0; "
      + "find -L \"$D\" -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.webp' \\) -print0 2>/dev/null | sort -z | tr '\\0' '\\n'"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.loadRows(String(text || ""))
    }
  }

  Process {
    id: queryProc
    command: ["awww", "query", "-j"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.syncCurrent(String(text || "{}"))
    }
  }

  Process {
    id: applyProc
    onExited: root.open = false
  }

  function fileUrl(path) {
    return "file://" + String(path).split("/").map(encodeURIComponent).join("/")
  }

  function loadRows(text) {
    const lines = String(text || "").split("\n").filter(l => l)
    const img = []
    const seen = {}
    for (const line of lines) {
      if (seen[line]) continue
      seen[line] = true
      const slash = line.lastIndexOf("/")
      img.push({ filePath: line, dir: slash > 0 ? line.substring(0, slash) : "/" })
    }
    root.images = img
    const dirSet = {}
    for (const it of img) dirSet[it.dir] = true
    const dirs = []
    for (const d in dirSet) dirs.push(d)
    dirs.sort()
    root.folders = dirs
    if (root.currentDirIndex >= dirs.length) root.currentDirIndex = 0
    root.refold()
    root.selectedIndex = 0
    root.updateFolderText()
  }

  function refold() {
    const dir = root.folders.length ? root.folders[root.currentDirIndex] : ""
    const list = []
    for (const it of root.images) if (it.dir === dir) list.push(it.filePath)
    root.folderImages = list
    if (root.selectedIndex >= list.length) root.selectedIndex = list.length - 1
    if (root.selectedIndex < 0) root.selectedIndex = 0
  }

  function folderStep(delta) {
    if (!root.folders.length) return
    const n = root.folders.length
    root.currentDirIndex = (root.currentDirIndex + delta + n) % n
    root.refold()
    root.selectedIndex = 0
    root.updateFolderText()
  }

  function updateFolderText() {
    const f = root.folders.length ? String(root.folders[root.currentDirIndex]) : ""
    root.folderText = f ? f.substring(f.lastIndexOf("/") + 1) : ""
  }

  function step(delta) {
    const n = root.folderImages.length
    if (n) root.selectedIndex = Math.max(0, Math.min(n - 1, root.selectedIndex + delta))
  }

  function applyCurrent() {
    const p = root.folderImages[root.selectedIndex]
    if (!p) return
    applyProc.command = ["awww", "img", "-t", "random", "--transition-fps", "144", "--", p]
    applyProc.running = false
    applyProc.running = true
  }

  function syncCurrent(jsonText) {
    let cur = ""
    try {
      const data = JSON.parse(jsonText)
      for (const ns in data) {
        const outs = data[ns]
        if (!Array.isArray(outs)) continue
        for (const o of outs) {
          if (o && o.displaying && o.displaying.image) { cur = o.displaying.image; break }
        }
        if (cur) break
      }
    } catch (e) { cur = "" }
    for (let i = 0; i < root.images.length; i++) {
      if (root.images[i].filePath === cur) {
        const di = root.folders.indexOf(root.images[i].dir)
        if (di >= 0) root.currentDirIndex = di
        root.refold()
        root.selectedIndex = root.folderImages.indexOf(cur)
        if (root.selectedIndex < 0) root.selectedIndex = 0
        root.updateFolderText()
        return
      }
    }
  }

  onOpenChanged: {
    if (root.open) {
      listProc.running = false
      listProc.running = true
    }
  }

  Connections {
    target: root
    function onImagesChanged() {
      queryProc.running = false
      queryProc.running = true
    }
  }

  PanelWindow {
    visible: root.open
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "qs-wallpapers"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onVisibleChanged: if (!visible) root.open = false

    MouseArea {
      anchors.fill: parent
      onClicked: root.open = false
    }

    Text {
      anchors.centerIn: parent
      visible: root.open && root.images.length === 0
      text: "no wallpapers in ~/Wallpapers"
      color: "#565a6e"
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 14
    }

    Column {
      anchors.centerIn: parent
      spacing: 10

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.open && root.images.length > 0
        text: root.folderText
        color: "#e6e7f0"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        font.bold: true
      }

Item {
        id: deck
        width: root.previewWidth + 2 * (root.radius * (root.sliceWidth + root.sliceSpacing))
        height: root.previewHeight
        focus: true
        onFocusChanged: if (focus) Qt.callLater(() => forceActiveFocus())

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: (event) => {
          if (event.key === Qt.Key_Escape) {
            root.open = false
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.applyCurrent()
            event.accepted = true
          } else if (event.key === Qt.Key_Left) {
            root.step(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Right) {
            root.step(1)
            event.accepted = true
          } else if (event.key === Qt.Key_Up) {
            root.folderStep(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Down) {
            root.folderStep(1)
            event.accepted = true
          }
        }

        Item {
          anchors.fill: parent
          visible: root.folderImages.length > 0

          readonly property real step: root.sliceWidth + root.sliceSpacing
          readonly property real centerX: (width - root.previewWidth) / 2

          Repeater {
            model: root.folderImages.length

            delegate: Item {
              id: cell
              required property int index

              readonly property int rel: index - root.selectedIndex
              readonly property bool selected: rel === 0

              readonly property real topLeft: root.skewOffset
              readonly property real topRight: width
              readonly property real bottomRight: width - root.skewOffset
              readonly property real bottomLeft: 0

              visible: Math.abs(rel) <= root.radius
              x: selected ? parent.centerX
                 : rel < 0 ? parent.centerX + rel * parent.step
                 : parent.centerX + root.previewWidth + root.sliceSpacing + (rel - 1) * parent.step
              y: selected ? 0 : (root.previewHeight - root.sliceHeight) / 2
              width: selected ? root.previewWidth : root.sliceWidth
              height: selected ? root.previewHeight : root.sliceHeight
              z: selected ? 10 : 5 - Math.min(Math.abs(rel), 4)

              Item {
                id: maskShape
                anchors.fill: parent
                visible: false
                layer.enabled: true

                Shape {
                  anchors.fill: parent
                  antialiasing: true
                  preferredRendererType: Shape.CurveRenderer

                  ShapePath {
                    fillColor: "white"
                    strokeColor: "transparent"
                    startX: cell.topLeft; startY: 0
                    PathLine { x: cell.topRight; y: 0 }
                    PathLine { x: cell.bottomRight; y: cell.height }
                    PathLine { x: cell.bottomLeft; y: cell.height }
                    PathLine { x: cell.topLeft; y: 0 }
                  }
                }
              }

              Item {
                anchors.fill: parent
                layer.enabled: true
                layer.smooth: true
                layer.effect: MultiEffect {
                  maskEnabled: true
                  maskSource: maskShape
                  maskThresholdMin: 0.3
                  maskSpreadAtMin: 0.3
                }

                Image {
                  id: image
                  anchors.fill: parent
                  source: root.fileUrl(root.folderImages[cell.index])
                  fillMode: Image.PreserveAspectCrop
                  sourceSize: Qt.size(900, 600)
                  asynchronous: true
                  smooth: true
                }

                Rectangle {
                  anchors.fill: parent
                  visible: image.status !== Image.Ready
                  color: "#23232e"
                }
              }

              Shape {
                anchors.fill: parent
                antialiasing: true
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                  fillColor: "transparent"
                  strokeColor: cell.selected ? "#7aa2f7" : "#565a6e"
                  strokeWidth: cell.selected ? 2 : 1
                  startX: cell.topLeft; startY: 0
                  PathLine { x: cell.topRight; y: 0 }
                  PathLine { x: cell.bottomRight; y: cell.height }
                  PathLine { x: cell.bottomLeft; y: cell.height }
                  PathLine { x: cell.topLeft; y: 0 }
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: cell.selected ? root.applyCurrent() : root.selectedIndex = cell.index
              }
            }
          }
        }
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.open && root.folderImages.length > 0
        text: root.folderImages[root.selectedIndex]
          ? String(root.folderImages[root.selectedIndex]).split("/").pop() : ""
        elide: Text.ElideMiddle
        color: "#e6e7f0"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
      }
    }
  }
}
