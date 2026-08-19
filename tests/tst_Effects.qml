import QtQuick 2.15
import QtTest 1.3
import ".." as Plugin

TestCase {
  id: testCase
  name: "SentimentEffects"
  width: 330
  height: 132

  Component {
    id: effectsComponent

    Plugin.SentimentEffects {
      width: 330
      height: 132
    }
  }

  Component {
    id: fireBedComponent

    Plugin.FireBed {
      width: 330
      height: 132
    }
  }

  Component {
    id: greedRainComponent

    Plugin.GreedRain {
      width: 330
      height: 132
    }
  }

  function effect(properties) {
    var item = createTemporaryObject(effectsComponent, testCase, properties || {})
    verify(item !== null)
    return item
  }

  function test_closedPanelDoesNotRun() {
    var item = effect({ score: 10, active: false, animationMode: "Full" })
    verify(!item.fearRunning)
    verify(!item.greedRunning)
    verify(!item.fireBedRunning)
    compare(item.greedDropCount, 0)
    compare(item.coinDropCount, 0)
    compare(item.moneyDropCount, 0)
  }

  function test_fearRunsOnlyForFear() {
    var item = effect({ score: 10, active: true, animationMode: "Full" })
    compare(item.effect, "fear")
    verify(item.fearRunning)
    verify(item.fireBedRunning)
    verify(!item.greedRunning)
  }

  function test_neutralDoesNotRun() {
    var item = effect({ score: 50, active: true, animationMode: "Full" })
    compare(item.effect, "none")
    verify(!item.fearRunning)
    verify(!item.greedRunning)
  }

  function test_greedRunsOnlyForGreed() {
    var item = effect({ score: 90, active: true, animationMode: "Full" })
    compare(item.effect, "greed")
    verify(!item.fearRunning)
    verify(!item.fireBedRunning)
    verify(item.greedRunning)
    verify(item.greedDropCount >= 12)
    verify(item.greedDropCount <= 24)
    verify(item.coinDropCount > item.moneyDropCount)
    verify(item.moneyDropCount > 0)
  }

  function test_subtleReducesRainDensity() {
    var full = effect({ score: 90, active: true, animationMode: "Full" })
    var subtle = effect({ score: 90, active: true, animationMode: "Subtle" })
    verify(subtle.greedDropCount < full.greedDropCount)
  }

  function test_offDisablesAnimation() {
    var item = effect({ score: 10, active: true, animationMode: "Off" })
    verify(!item.fearRunning)
    verify(!item.greedRunning)
    verify(!item.fireBedRunning)
    compare(item.modeScale, 0)
  }

  function test_fireBedRunsContinuouslyOnlyWhenEnabled() {
    var item = createTemporaryObject(fireBedComponent, testCase,
                                     { running: true, intensity: 0.8 })
    verify(item !== null)
    verify(String(item.assetSource).indexOf("assets/flame-bed.svg") >= 0)
    verify(String(item.rigSource).indexOf("assets/flame-bed-rig.svg") >= 0)
    verify(String(item.shaderSource).indexOf("shaders/flame-warp.frag.qsb") >= 0)
    tryCompare(item, "assetReady", true)
    tryCompare(item, "animationsRunning", true)
    var initialTime = item.turbulenceTime
    tryVerify(function() { return item.turbulenceTime > initialTime })
    item.running = false
    tryCompare(item, "animationsRunning", false)
  }

  function test_fireBedProminenceTracksFearIntensity() {
    var moderate = createTemporaryObject(fireBedComponent, testCase,
                                         { running: true, intensity: 0.5 })
    var extreme = createTemporaryObject(fireBedComponent, testCase,
                                        { running: true, intensity: 1.0 })
    verify(moderate !== null)
    verify(extreme !== null)
    verify(extreme.flameHeightScale > moderate.flameHeightScale)
    verify(extreme.flameOpacity > moderate.flameOpacity)
    verify(extreme.turbulenceStrength > moderate.turbulenceStrength)
  }

  function test_greedRainUsesTumblingCoinDominantDensity() {
    var moderate = createTemporaryObject(greedRainComponent, testCase,
                                         { running: true, intensity: 0.4 })
    var high = createTemporaryObject(greedRainComponent, testCase,
                                     { running: true, intensity: 0.7 })
    var extreme = createTemporaryObject(greedRainComponent, testCase,
                                        { running: true, intensity: 1.0 })
    verify(moderate !== null)
    verify(high !== null)
    verify(extreme !== null)
    verify(String(extreme.coinSource).indexOf("assets/coin-generated.png") >= 0)
    verify(String(extreme.moneySource).indexOf("assets/money-generated.png") >= 0)
    verify(extreme.activeDropCount > moderate.activeDropCount)
    verify(extreme.activeDropCount - high.activeDropCount
           > high.activeDropCount - moderate.activeDropCount)
    compare(extreme.activeDropCount, extreme.totalDropCount)
    verify(extreme.activeCoinCount > extreme.activeBillCount)
    verify(extreme.dropOpacity > moderate.dropOpacity)
    verify(extreme.fallSpeedScale < moderate.fallSpeedScale)
    extreme.running = false
    compare(extreme.activeDropCount, 0)
    verify(!extreme.animationsRunning)
  }

  function test_switchingBandsResetsRunningState() {
    var item = effect({ score: 10, active: true, animationMode: "Full" })
    verify(item.fearRunning)
    item.score = 90
    tryCompare(item, "greedRunning", true)
    verify(!item.fearRunning)
    verify(item.coinDropCount > item.moneyDropCount)
    item.active = false
    tryCompare(item, "greedRunning", false)
    tryCompare(item, "greedDropCount", 0)
  }
}
