import QtQuick 2.15

Item {
  id: root

  property bool running: false
  property real intensity: 0
  property real glowPulse: 0
  property real turbulenceTime: 0

  readonly property url assetSource: Qt.resolvedUrl("assets/flame-bed.svg")
  readonly property url rigSource: Qt.resolvedUrl("assets/flame-bed-rig.svg")
  readonly property url shaderSource: Qt.resolvedUrl("shaders/flame-warp.frag.qsb")
  readonly property bool assetReady: shaderSourceImage.status === Image.Ready
  readonly property bool animationsRunning: running && intensity > 0

  visible: animationsRunning
  clip: true

  SequentialAnimation on glowPulse {
    running: root.animationsRunning
    loops: Animation.Infinite
    NumberAnimation { from: 0; to: 1; duration: 620; easing.type: Easing.InOutSine }
    NumberAnimation { from: 1; to: 0; duration: 760; easing.type: Easing.InOutSine }
  }

  NumberAnimation on turbulenceTime {
    running: root.animationsRunning
    loops: Animation.Infinite
    from: 0
    to: 100
    duration: 50000
  }

  Image {
    id: shaderSourceImage
    objectName: "flameBedAsset"
    width: root.width
    height: root.height
    source: root.assetSource
    sourceSize.width: 992
    sourceSize.height: 397
    fillMode: Image.Stretch
    cache: true
    smooth: true
    mipmap: true
    visible: false
  }

  ShaderEffect {
    id: proceduralFlames
    anchors.fill: parent
    property real time: root.turbulenceTime
    property real strength: 0.72 + 0.28 * root.intensity
    fragmentShader: root.shaderSource
    opacity: 0.44 + 0.56 * root.intensity
  }

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 5
    radius: 2
    color: "#f97316"
    opacity: 0.42 + 0.22 * root.intensity + 0.12 * root.glowPulse
  }
}
