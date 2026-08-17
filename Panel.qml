import QtQuick
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.davidojedalopez.fear-greed"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.5)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool hasData: hostWidget ? hostWidget.hasData : false
  readonly property int value: hasData ? hostWidget.value : -1
  readonly property string classification: hasData ? hostWidget.classification : ""
  readonly property var comparisons: hasData ? hostWidget.comparisons : []
  readonly property color sentimentColor: hostWidget
    ? hostWidget.colorForValue(value) : foreground

  function open() {
    root.controller.show()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (bar && typeof bar.switchPanelFrom === "function")
      return bar.switchPanelFrom(barIdentity, direction)
    return false
  }

  function openSource() {
    if (hostWidget) hostWidget.openSource()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(330))
    contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(540))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onActivateRequested: root.openSource()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: content
        anchors.fill: parent
        spacing: Style.space(12)

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: "MARKET FEAR & GREED · STOCKS"
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
          font.letterSpacing: 1.1
        }

        Item {
          width: parent.width
          height: Style.space(132)

          Canvas {
            id: gauge
            anchors.fill: parent

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Component.onCompleted: requestPaint()

            onPaint: {
              var ctx = getContext("2d")
              ctx.reset()

              var centerX = width / 2
              var centerY = height - Style.space(18)
              var radius = Math.min(width * 0.42, height - Style.space(30))
              var lineWidth = Style.space(10)
              var ranges = [0, 25, 45, 56, 75, 100]
              var colors = ["#ef4444", "#f97316", "#eab308", "#84cc16", "#22c55e"]
              var gap = 0.018

              ctx.lineWidth = lineWidth
              ctx.lineCap = "butt"
              for (var i = 0; i < colors.length; i++) {
                var start = Math.PI + (ranges[i] / 100) * Math.PI + gap
                var end = Math.PI + (ranges[i + 1] / 100) * Math.PI - gap
                ctx.beginPath()
                ctx.arc(centerX, centerY, radius, start, end, false)
                ctx.strokeStyle = colors[i]
                ctx.stroke()
              }

              if (root.hasData) {
                var angle = Math.PI + (Math.max(0, Math.min(100, root.value)) / 100) * Math.PI
                var needleRadius = radius - lineWidth * 0.9
                ctx.beginPath()
                ctx.moveTo(centerX, centerY)
                ctx.lineTo(centerX + Math.cos(angle) * needleRadius,
                           centerY + Math.sin(angle) * needleRadius)
                ctx.lineWidth = Math.max(2, Style.space(2))
                ctx.lineCap = "round"
                ctx.strokeStyle = root.foreground
                ctx.stroke()

                ctx.beginPath()
                ctx.arc(centerX, centerY, Style.space(4), 0, Math.PI * 2, false)
                ctx.fillStyle = root.foreground
                ctx.fill()
              }
            }
          }

          Connections {
            target: root
            function onValueChanged() { gauge.requestPaint() }
            function onForegroundChanged() { gauge.requestPaint() }
          }

          Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Style.space(42)
            spacing: 0

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.hasData ? String(root.value) : "--"
              color: root.sentimentColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.displayLarge
              font.bold: true
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.classification || (root.hostWidget && root.hostWidget.loading ? "Updating…" : "Unavailable")
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }
          }

          Text {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            text: "0"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Text {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            text: "100"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: root.hostWidget ? root.hostWidget.updatedLabel() : "Waiting for the first update"
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        PanelSeparator { foreground: root.foreground }

        Column {
          width: parent.width
          spacing: Style.space(7)

          Repeater {
            model: root.comparisons

            Row {
              required property var modelData
              width: parent.width
              spacing: Style.space(8)

              Text {
                width: Style.space(82)
                text: modelData.label
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
              }

              Item {
                width: Math.max(0, parent.width - Style.space(82) - Style.space(44) - Style.space(8))
                height: 1
              }

              Text {
                width: Style.space(44)
                horizontalAlignment: Text.AlignRight
                text: String(modelData.value)
                color: root.hostWidget ? root.hostWidget.colorForValue(modelData.value) : root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.subtitle
                font.bold: true
              }
            }
          }
        }

        Text {
          visible: root.hostWidget && root.hostWidget.errorText !== ""
          width: parent.width
          text: (root.hasData ? "Update failed · showing last good value\n" : "Update failed\n")
            + (root.hostWidget ? root.hostWidget.errorText : "")
          wrapMode: Text.Wrap
          color: "#ef4444"
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        PanelSeparator { foreground: root.foreground }

        Row {
          width: parent.width

          Text {
            text: root.hostWidget && root.hostWidget.loading ? "Refreshing…"
              : (root.hostWidget && root.hostWidget.stale ? "Cached · updates daily" : "Updates daily")
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Item {
            width: Math.max(0, parent.width - parent.children[0].implicitWidth - sourceLink.implicitWidth)
            height: 1
          }

          Text {
            id: sourceLink
            text: "Source: CNN"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.underline: true

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.openSource()
            }
          }
        }
      }
    }
  }
}

