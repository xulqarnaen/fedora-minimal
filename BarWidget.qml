import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.ibr.cava"

  property var levels: []
  readonly property int barCount: Number(setting("bars", 24))
  readonly property real barWidth: Number(setting("barWidth", 3))
  readonly property real barGap: Number(setting("barGap", 2))
  readonly property real visualHeight: Math.max(16, Math.min(barSize - 6, Number(setting("height", 20))))
  readonly property color visualColor: root.bar ? root.bar.barForeground : Color.foreground
  readonly property string configPath: Qt.resolvedUrl("cava.conf").toString().replace("file://", "")
  readonly property var mediaService: bar?.shell?.firstPartyServiceFor("omarchy.media")
  readonly property var activePlayer: mediaService ? mediaService.activePlayer : null

  function parseFrame(line) {
    var fields = String(line).trim().split(";")
    var next = []
    for (var i = 0; i < barCount; ++i) {
      var raw = i < fields.length ? Number(fields[i]) : 0
      if (!isFinite(raw)) raw = 0
      next.push(Math.max(0, Math.min(8, raw)) / 8)
    }
    levels = next
  }

  function start() {
    if (!cava.running) cava.running = true
  }

  function stop() {
    if (cava.running) cava.running = false
  }

  implicitWidth: root.vertical ? barSize : (barCount * barWidth + (barCount - 1) * barGap + Style.space(10))
  implicitHeight: root.vertical ? (barCount * barWidth + (barCount - 1) * barGap + Style.space(10)) : barSize

  Component.onCompleted: start()
  Component.onDestruction: stop()

  Process {
    id: cava
    command: ["cava", "-p", root.configPath]

    stdout: SplitParser {
      onRead: function(data) { root.parseFrame(data) }
    }

    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0) retry.restart()
    }
  }

  Timer {
    id: retry
    interval: 1500
    repeat: false
    onTriggered: root.start()
  }

  Row {
    id: horizontalBars
    visible: !root.vertical
    anchors.centerIn: parent
    spacing: root.barGap

    Repeater {
      model: root.barCount

      Rectangle {
        required property int index
        width: root.barWidth
        height: Math.max(2, root.visualHeight * ((root.levels[index] || 0) + 0.08))
        anchors.verticalCenter: parent.verticalCenter
        radius: Math.min(width / 2, 2)
        color: root.visualColor
        opacity: 0.45 + (root.levels[index] || 0) * 0.55

        Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
      }
    }
  }

  Column {
    id: verticalBars
    visible: root.vertical
    anchors.centerIn: parent
    spacing: root.barGap

    Repeater {
      model: root.barCount

      Rectangle {
        required property int index
        width: Math.max(2, root.visualHeight * ((root.levels[index] || 0) + 0.08))
        height: root.barWidth
        anchors.horizontalCenter: parent.horizontalCenter
        radius: Math.min(height / 2, 2)
        color: root.visualColor
        opacity: 0.45 + (root.levels[index] || 0) * 0.55

        Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function(mouse) {
      if (mouse.button === Qt.LeftButton) {
        if (root.mediaService && root.activePlayer)
          root.mediaService.runAction("playPause", false)
      } else if (mouse.button === Qt.RightButton && root.bar) {
        root.bar.run("omarchy-launch-or-focus-tui cava")
      }
    }
    onEntered: if (root.bar) root.bar.showTooltip(root, "Left click: play/pause  •  Right click: open CAVA")
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }
}
