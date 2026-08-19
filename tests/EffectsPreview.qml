import QtQuick 2.15
import QtQuick.Window 2.15
import ".." as Plugin
import "../Model.js" as Model

Window {
  id: root
  width: 410
  height: 240
  visible: true
  color: "#09090b"
  title: "Fear & Greed Effects Preview"

  property var scores: [10, 35, 50, 65, 90]
  property int scoreIndex: 0
  property var modes: ["Full", "Subtle", "Off"]
  property int modeIndex: 0
  property string capturePath: ""
  readonly property int score: scores[scoreIndex]
  readonly property string animationMode: modes[modeIndex]

  function advanceScore() {
    scoreIndex = (scoreIndex + 1) % scores.length
  }

  function advanceMode() {
    modeIndex = (modeIndex + 1) % modes.length
  }

  function applyArguments() {
    var args = Qt.application.arguments
    for (var i = 1; i < args.length; i++) {
      if (String(args[i]).indexOf("--capture=") === 0) {
        capturePath = String(args[i]).slice(10)
        continue
      }
      var requestedScore = Number(args[i])
      var requestedIndex = scores.indexOf(requestedScore)
      if (requestedIndex >= 0) scoreIndex = requestedIndex
    }
  }

  Timer {
    interval: 1200
    running: root.capturePath !== ""
    repeat: false
    onTriggered: stage.grabToImage(function(result) {
      if (!result.saveToFile(root.capturePath))
        console.error("Could not save preview capture: " + root.capturePath)
      Qt.quit()
    })
  }

  Item {
    anchors.fill: parent
    focus: true
    Component.onCompleted: {
      root.applyArguments()
      forceActiveFocus()
    }

    Keys.onPressed: function(event) {
      if (event.key >= Qt.Key_1 && event.key <= Qt.Key_5) {
        root.scoreIndex = event.key - Qt.Key_1
        event.accepted = true
      } else if (event.key === Qt.Key_Space) {
        root.advanceMode()
        event.accepted = true
      }
    }

    Rectangle {
      id: stage
      width: 330
      height: 132
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 28
      radius: 12
      color: "#18181b"
      clip: true

      Plugin.SentimentEffects {
        anchors.fill: parent
        score: root.score
        active: true
        animationMode: root.animationMode
      }

      Text {
        anchors.centerIn: parent
        z: 2
        text: root.score + "\n" + Model.classificationForValue(root.score)
        color: Model.colorForValue(root.score)
        font.pixelSize: 28
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
      }

      MouseArea {
        anchors.fill: parent
        onClicked: root.advanceScore()
      }
    }

    Text {
      anchors.top: stage.bottom
      anchors.topMargin: 16
      anchors.horizontalCenter: parent.horizontalCenter
      text: "Animation: " + root.animationMode
        + "  ·  click for score  ·  Space for mode  ·  keys 1–5"
      color: "#a1a1aa"
      font.pixelSize: 12
    }
  }
}
