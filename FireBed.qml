import QtQuick 2.15

Item {
  id: root

  property bool running: false
  property real intensity: 0
  property real turbulenceTime: 0

  readonly property url assetSource: Qt.resolvedUrl("assets/flame-bed.svg")
  readonly property url rigSource: Qt.resolvedUrl("assets/flame-bed-rig.svg")
  readonly property url shaderSource: Qt.resolvedUrl("shaders/flame-warp.frag.qsb")
  readonly property bool assetReady: shaderSourceImage.status === Image.Ready
  readonly property bool animationsRunning: running && intensity > 0
  readonly property real normalizedIntensity: Math.max(0, Math.min(1, intensity))
  readonly property real flameHeightScale: 0.70 + 0.50 * normalizedIntensity
  readonly property real flameOpacity: 0.44 + 0.56 * normalizedIntensity
  readonly property real turbulenceStrength: 0.55 + 0.55 * normalizedIntensity

  visible: animationsRunning
  clip: true

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
    property real strength: root.turbulenceStrength
    property real heightScale: root.flameHeightScale
    fragmentShader: root.shaderSource
    opacity: root.flameOpacity
  }

}
