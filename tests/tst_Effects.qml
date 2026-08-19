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

  function effect(properties) {
    var item = createTemporaryObject(effectsComponent, testCase, properties || {})
    verify(item !== null)
    return item
  }

  function test_closedPanelDoesNotRun() {
    var item = effect({ score: 10, active: false, animationMode: "Full" })
    verify(!item.fearRunning)
    verify(!item.greedRunning)
    compare(item.fearEmitRate, 0)
  }

  function test_fearRunsOnlyForFear() {
    var item = effect({ score: 10, active: true, animationMode: "Full" })
    compare(item.effect, "fear")
    verify(item.fearRunning)
    verify(!item.greedRunning)
    verify(item.fearEmitRate >= 4)
    verify(item.fearEmitRate <= 8)
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
    verify(item.greedRunning)
    verify(item.greedEmitRate >= 2)
    verify(item.greedEmitRate <= 5)
  }

  function test_subtleHalvesEmission() {
    var full = effect({ score: 90, active: true, animationMode: "Full" })
    var subtle = effect({ score: 90, active: true, animationMode: "Subtle" })
    fuzzyCompare(subtle.greedEmitRate, full.greedEmitRate / 2, 0.0001)
    verify(subtle.particleAlpha < full.particleAlpha)
  }

  function test_offDisablesAnimation() {
    var item = effect({ score: 10, active: true, animationMode: "Off" })
    verify(!item.fearRunning)
    verify(!item.greedRunning)
    compare(item.modeScale, 0)
  }

  function test_switchingBandsResetsRunningState() {
    var item = effect({ score: 10, active: true, animationMode: "Full" })
    verify(item.fearRunning)
    item.score = 90
    tryCompare(item, "greedRunning", true)
    verify(!item.fearRunning)
    item.active = false
    tryCompare(item, "greedRunning", false)
  }
}
