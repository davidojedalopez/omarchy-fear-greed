import QtQuick 2.15

Item {
  id: root

  property bool running: false
  property real intensity: 0

  readonly property url coinSource: Qt.resolvedUrl("assets/coin-generated.png")
  readonly property url moneySource: Qt.resolvedUrl("assets/money-generated.png")
  readonly property real normalizedIntensity: Math.max(0, Math.min(1, intensity))
  readonly property real extremeProgress: Math.max(0, Math.min(1,
    (normalizedIntensity - 0.4) / 0.6))
  readonly property real greedSurge: extremeProgress * extremeProgress
  readonly property int totalDropCount: 24
  readonly property int activeDropCount: running
    ? Math.round(8 + 16 * greedSurge) : 0
  readonly property int activeBillCount: Math.floor(activeDropCount / 6)
  readonly property int activeCoinCount: activeDropCount - activeBillCount
  readonly property real dropOpacity: 0.50 + 0.50 * normalizedIntensity
  readonly property real fallSpeedScale: 1.12 - 0.32 * greedSurge
  readonly property bool animationsRunning: running && activeDropCount > 0

  visible: animationsRunning
  clip: true

  Repeater {
    model: root.totalDropCount

    delegate: Item {
      id: drop

      required property int index

      property bool bill: index % 6 === 5
      property bool enabledDrop: index < root.activeDropCount
      property real visualSize: bill ? 30 + (index * 7) % 7
                                     : 18 + (index * 5) % 9
      readonly property real horizontalSeed: ((index + 1) * 137 % 997) / 997
      readonly property real driftSeed: ((index + 1) * 419 % 997) / 997
      readonly property real motionSeed: ((index + 1) * 613 % 997) / 997
      readonly property real startX: -visualSize * 0.20 + horizontalSeed * root.width
      readonly property real endX: startX + (driftSeed - 0.5) * 72
      readonly property real initialFlip: motionSeed * 180
      readonly property real finalFlip: initialFlip
        + 360 * (2 + ((index * 5) % 3))
      readonly property real initialRoll: ((index * 271) % 997) / 997 * 360
      readonly property real finalRoll: initialRoll
        + (index % 2 === 0 ? 1 : -1) * (210 + ((index * 47) % 360))
      readonly property int travelDuration: Math.round((1450 + motionSeed * 700)
                                                       * root.fallSpeedScale)
      readonly property int repeatGap: 80 + (index * 97) % 420
      readonly property int initialDelay: (index * 173) % 1100

      property real flipAngle: initialFlip
      property real rollAngle: initialRoll

      objectName: bill ? "moneyDrop" : "coinDrop"
      width: visualSize
      height: visualSize
      y: -visualSize - 8
      visible: enabledDrop && root.running
      opacity: root.dropOpacity * (0.80 + 0.05 * ((index * 3) % 5))

      Image {
        id: artwork
        anchors.centerIn: parent
        width: drop.bill ? drop.visualSize * 1.22 : drop.visualSize
        height: drop.bill ? drop.visualSize * 0.84 : drop.visualSize
        source: drop.bill ? root.moneySource : root.coinSource
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true

        transform: [
          Rotation {
            origin.x: artwork.width / 2
            origin.y: artwork.height / 2
            axis { x: drop.bill ? 1 : 0; y: drop.bill ? 0 : 1; z: 0 }
            angle: drop.flipAngle
          },
          Rotation {
            origin.x: artwork.width / 2
            origin.y: artwork.height / 2
            axis { x: 0; y: 0; z: 1 }
            angle: drop.rollAngle
          }
        ]
      }

      SequentialAnimation {
        running: drop.enabledDrop && root.running
        loops: Animation.Infinite

        PauseAnimation {
          duration: drop.initialDelay
        }
        ParallelAnimation {
          NumberAnimation {
            target: drop
            property: "y"
            from: -drop.visualSize - 8
            to: root.height + drop.visualSize + 8
            duration: drop.travelDuration
            easing.type: Easing.InQuad
          }
          NumberAnimation {
            target: drop
            property: "x"
            from: drop.startX
            to: drop.endX
            duration: drop.travelDuration
            easing.type: Easing.InOutSine
          }
          NumberAnimation {
            target: drop
            property: "flipAngle"
            from: drop.initialFlip
            to: drop.finalFlip
            duration: drop.travelDuration
          }
          NumberAnimation {
            target: drop
            property: "rollAngle"
            from: drop.initialRoll
            to: drop.finalRoll
            duration: drop.travelDuration
          }
        }
        PauseAnimation {
          duration: drop.repeatGap
        }
      }
    }
  }
}
