import QtQuick
import qs.Commons
import qs.Ui
import "Model.js" as Model

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
  readonly property string animationMode: Model.normalizedAnimationMode(
    root.setting("animationMode", "Full"))

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
    contentWidth: panel.fittedContentWidth(Style.space(370))
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
          height: Style.space(180)
          clip: true

          SentimentEffects {
            anchors.fill: parent
            score: root.value
            active: root.opened && root.hasData
            animationMode: root.animationMode
          }

          Canvas {
            id: gauge
            anchors.fill: parent
            z: 1
            readonly property real pivotY: height - Style.space(34)
            readonly property real radialRadius: Math.min(
              width * 0.36, pivotY - Style.space(25))

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Component.onCompleted: requestPaint()

            onPaint: {
              var ctx = getContext("2d")
              ctx.reset()

              var centerX = width / 2
              var centerY = pivotY
              var radius = radialRadius
              var lineWidth = Style.space(44)
              var ranges = [0, 25, 45, 56, 75, 100]
              var colors = ["#ef4444", "#f97316", "#eab308", "#84cc16", "#22c55e"]
              var gap = 0.026
              var activeBand = 0
              for (var band = 0; band < colors.length; band++) {
                if (root.value >= ranges[band]
                    && root.value <= ranges[band + 1]) activeBand = band
              }

              ctx.lineWidth = lineWidth
              ctx.lineCap = "butt"
              for (var i = 0; i < colors.length; i++) {
                var start = Math.PI + (ranges[i] / 100) * Math.PI + gap
                var end = Math.PI + (ranges[i + 1] / 100) * Math.PI - gap
                ctx.beginPath()
                ctx.arc(centerX, centerY, radius, start, end, false)
                ctx.strokeStyle = i === activeBand ? colors[i] : "#27272a"
                ctx.stroke()
              }

              if (root.hasData) {
                var angle = Math.PI + (Math.max(0, Math.min(100, root.value)) / 100) * Math.PI
                var needleRadius = radius - lineWidth * 0.34
                var needleEndX = centerX + Math.cos(angle) * needleRadius
                var needleEndY = centerY + Math.sin(angle) * needleRadius
                ctx.beginPath()
                ctx.moveTo(centerX, centerY)
                ctx.lineTo(needleEndX, needleEndY)
                ctx.lineWidth = Style.space(5)
                ctx.lineCap = "butt"
                ctx.strokeStyle = root.foreground
                ctx.stroke()

                var arrowLength = Style.space(12)
                var arrowHalfWidth = Style.space(6)
                var arrowBaseX = needleEndX - Math.cos(angle) * arrowLength
                var arrowBaseY = needleEndY - Math.sin(angle) * arrowLength
                var normalX = -Math.sin(angle)
                var normalY = Math.cos(angle)
                ctx.beginPath()
                ctx.moveTo(needleEndX, needleEndY)
                ctx.lineTo(arrowBaseX + normalX * arrowHalfWidth,
                           arrowBaseY + normalY * arrowHalfWidth)
                ctx.moveTo(needleEndX, needleEndY)
                ctx.lineTo(arrowBaseX - normalX * arrowHalfWidth,
                           arrowBaseY - normalY * arrowHalfWidth)
                ctx.lineWidth = Style.space(3)
                ctx.lineCap = "butt"
                ctx.lineJoin = "miter"
                ctx.strokeStyle = root.foreground
                ctx.stroke()

                ctx.beginPath()
                ctx.arc(centerX, centerY, Style.space(32), 0, Math.PI * 2, false)
                ctx.fillStyle = "#101118"
                ctx.fill()
              }
            }
          }

          Connections {
            target: root
            function onValueChanged() { gauge.requestPaint() }
            function onForegroundChanged() { gauge.requestPaint() }
          }

          Item {
            id: radialLabels
            anchors.fill: parent
            z: 2

            Repeater {
              model: [
                { label: "EXTREME FEAR", min: 0, max: 24 },
                { label: "FEAR", min: 25, max: 44 },
                { label: "NEUTRAL", min: 45, max: 55 },
                { label: "GREED", min: 56, max: 74 },
                { label: "EXTREME GREED", min: 75, max: 100 }
              ]

              delegate: Item {
                id: arcLabel
                required property var modelData
                anchors.fill: parent
                readonly property string labelText: modelData.label
                readonly property real middleAngle: Math.PI
                  + ((modelData.min + modelData.max) / 200) * Math.PI
                readonly property real letterStep: 0.046
                readonly property color labelColor:
                  root.value >= modelData.min && root.value <= modelData.max
                    ? root.foreground : root.dim

                Repeater {
                  model: arcLabel.labelText.length

                  delegate: Text {
                    required property int index
                    readonly property real letterAngle: arcLabel.middleAngle
                      + (index - (arcLabel.labelText.length - 1) / 2)
                        * arcLabel.letterStep
                    x: radialLabels.width / 2
                      + Math.cos(letterAngle) * gauge.radialRadius - width / 2
                    y: gauge.pivotY
                      + Math.sin(letterAngle) * gauge.radialRadius - height / 2
                    rotation: letterAngle * 180 / Math.PI + 90
                    text: arcLabel.labelText.charAt(index)
                    color: arcLabel.labelColor
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }
                }
              }
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              y: gauge.pivotY - height / 2
              text: root.hasData ? String(root.value) : "--"
              color: root.sentimentColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.displayLarge
              font.bold: true
            }
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
