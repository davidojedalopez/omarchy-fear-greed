import QtQuick 2.15
import QtQuick.Particles 2.15
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
  readonly property real fearEmitRate: fearRunning ? 8 * bandIntensity * modeScale : 0
  readonly property real greedEmitRate: greedRunning ? 5 * bandIntensity * modeScale : 0
  readonly property real particleAlpha: 0.16 + 0.24 * visualIntensity

  visible: fearRunning || greedRunning
  clip: true

  function resetInactiveSystems() {
    if (!fearRunning) fearSystem.reset()
    if (!greedRunning) greedSystem.reset()
  }

  onActiveChanged: resetInactiveSystems()
  onEffectChanged: resetInactiveSystems()
  onAnimationModeChanged: resetInactiveSystems()

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: parent.height * 0.55
    opacity: root.fearRunning ? 0.05 + 0.08 * root.visualIntensity : 0

    gradient: Gradient {
      GradientStop { position: 0; color: "transparent" }
      GradientStop { position: 1; color: "#80ef4444" }
    }

    Behavior on opacity {
      NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }
  }

  ParticleSystem {
    id: fearSystem
    running: root.fearRunning
  }

  Emitter {
    system: fearSystem
    group: "flames"
    enabled: root.fearRunning
    x: 0
    y: root.height - 2
    width: root.width
    height: 1
    emitRate: root.fearEmitRate
    lifeSpan: 1350
    lifeSpanVariation: 300
    size: 23
    sizeVariation: 8
    endSize: 8
    velocity: PointDirection {
      y: -68
      yVariation: 18
      xVariation: 11
    }
    acceleration: PointDirection {
      y: -8
      xVariation: 3
    }
  }

  ImageParticle {
    system: fearSystem
    groups: ["flames"]
    source: Qt.resolvedUrl("assets/flame.svg")
    color: "#f97316"
    colorVariation: 0.12
    alpha: root.particleAlpha
    alphaVariation: 0.08
    rotationVariation: 16
    rotationVelocityVariation: 18
    entryEffect: ImageParticle.Scale
  }

  ParticleSystem {
    id: greedSystem
    running: root.greedRunning
  }

  Emitter {
    system: greedSystem
    group: "money"
    enabled: root.greedRunning
    x: 0
    y: -20
    width: root.width
    height: 1
    emitRate: root.greedEmitRate
    lifeSpan: 2450
    lifeSpanVariation: 350
    size: 24
    sizeVariation: 6
    endSize: 19
    velocity: PointDirection {
      y: 48
      yVariation: 14
      xVariation: 12
    }
    acceleration: PointDirection {
      y: 18
      xVariation: 2
    }
  }

  ImageParticle {
    system: greedSystem
    groups: ["money"]
    source: Qt.resolvedUrl("assets/money.svg")
    color: "#22c55e"
    colorVariation: 0.08
    alpha: root.particleAlpha
    alphaVariation: 0.06
    rotationVariation: 20
    rotationVelocityVariation: 55
    entryEffect: ImageParticle.Fade
  }
}
