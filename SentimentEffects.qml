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
  readonly property real fearEmitRate: fearRunning ? 3 * bandIntensity * modeScale : 0
  readonly property real greedEmitRate: greedRunning ? 5 * bandIntensity * modeScale : 0
  readonly property real coinEmitRate: greedRunning ? 3 * bandIntensity * modeScale : 0
  readonly property real particleAlpha: 0.16 + 0.24 * visualIntensity
  readonly property real emberAlpha: 0.08 + 0.16 * visualIntensity
  readonly property bool fireBedRunning: fireBed.animationsRunning

  visible: fearRunning || greedRunning
  clip: true

  function resetInactiveSystems() {
    if (!fearRunning) fearSystem.reset()
    if (!greedRunning) greedSystem.reset()
  }

  onActiveChanged: resetInactiveSystems()
  onEffectChanged: resetInactiveSystems()
  onAnimationModeChanged: resetInactiveSystems()

  FireBed {
    id: fireBed
    anchors.fill: parent
    running: root.fearRunning
    intensity: root.visualIntensity
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
    lifeSpan: 1200
    lifeSpanVariation: 260
    size: 7
    sizeVariation: 3
    endSize: 2
    velocity: PointDirection {
      y: -46
      yVariation: 14
      xVariation: 8
    }
    acceleration: PointDirection {
      y: -8
      xVariation: 3
    }
  }

  ImageParticle {
    objectName: "fearParticles"
    system: fearSystem
    groups: ["flames"]
    opacity: root.fearRunning ? 1 : 0
    source: Qt.resolvedUrl("assets/flame.svg")
    color: "#fb923c"
    colorVariation: 0.08
    alpha: root.emberAlpha
    alphaVariation: 0.05
    rotationVariation: 30
    rotationVelocityVariation: 24
    entryEffect: ImageParticle.Fade
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
    objectName: "moneyParticles"
    system: greedSystem
    groups: ["money"]
    opacity: root.greedRunning ? 1 : 0
    source: Qt.resolvedUrl("assets/money.svg")
    color: "#22c55e"
    colorVariation: 0.08
    alpha: root.particleAlpha
    alphaVariation: 0.06
    rotationVariation: 20
    rotationVelocityVariation: 55
    entryEffect: ImageParticle.Fade
  }

  Emitter {
    system: greedSystem
    group: "coins"
    enabled: root.greedRunning
    x: 0
    y: -16
    width: root.width
    height: 1
    emitRate: root.coinEmitRate
    lifeSpan: 2200
    lifeSpanVariation: 300
    size: 18
    sizeVariation: 5
    endSize: 15
    velocity: PointDirection {
      y: 58
      yVariation: 16
      xVariation: 16
    }
    acceleration: PointDirection {
      y: 22
      xVariation: 3
    }
  }

  ImageParticle {
    objectName: "coinParticles"
    system: greedSystem
    groups: ["coins"]
    opacity: root.greedRunning ? 1 : 0
    source: Qt.resolvedUrl("assets/coin.svg")
    color: "#facc15"
    colorVariation: 0.06
    alpha: Math.min(0.48, root.particleAlpha + 0.08)
    alphaVariation: 0.05
    rotationVariation: 180
    rotationVelocity: 95
    rotationVelocityVariation: 110
    entryEffect: ImageParticle.Scale
  }
}
