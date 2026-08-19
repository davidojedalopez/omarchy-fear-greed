import QtQuick 2.15
import "Model.js" as Model

Item {
  id: root

  property int score: -1
  property bool active: false
  property string animationMode: "Full"

  readonly property string effect: Model.effectForValue(score)
  readonly property real bandIntensity: Model.effectIntensityForValue(score)
  readonly property real modeScale: Model.animationModeScale(animationMode)
  readonly property real visualIntensity: bandIntensity * modeScale
  readonly property bool fearRunning: active && effect === "fear" && modeScale > 0
  readonly property bool greedRunning: active && effect === "greed" && modeScale > 0
  readonly property int greedDropCount: greedRain.activeDropCount
  readonly property int coinDropCount: greedRain.activeCoinCount
  readonly property int moneyDropCount: greedRain.activeBillCount
  readonly property bool fireBedRunning: fireBed.animationsRunning

  visible: fearRunning || greedRunning
  clip: true

  FireBed {
    id: fireBed
    anchors.fill: parent
    running: root.fearRunning
    intensity: root.visualIntensity
  }

  GreedRain {
    id: greedRain
    anchors.fill: parent
    running: root.greedRunning
    intensity: root.visualIntensity
  }
}
