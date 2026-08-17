import QtQuick 2.15
import QtTest 1.3
import "../Model.js" as Model

TestCase {
  name: "FearGreedModel"

  function validPayload(overrides) {
    var current = {
      score: 64.6,
      rating: "greed",
      timestamp: "2026-08-14T23:59:53+00:00",
      previous_close: 66.1,
      previous_1_week: 64.4,
      previous_1_month: 41.1,
      previous_1_year: 63.3
    }
    var values = overrides || {}
    for (var key in values) current[key] = values[key]
    return JSON.stringify({ fear_and_greed: current })
  }

  function curlEnvelope(body, status, contentType) {
    return body + Model.RESPONSE_MARKER + status + "|" + contentType
  }

  function test_scoreBands() {
    compare(Model.classificationForValue(0), "Extreme Fear")
    compare(Model.classificationForValue(24), "Extreme Fear")
    compare(Model.classificationForValue(25), "Fear")
    compare(Model.classificationForValue(44), "Fear")
    compare(Model.classificationForValue(45), "Neutral")
    compare(Model.classificationForValue(55), "Neutral")
    compare(Model.classificationForValue(56), "Greed")
    compare(Model.classificationForValue(74), "Greed")
    compare(Model.classificationForValue(75), "Extreme Greed")
    compare(Model.classificationForValue(100), "Extreme Greed")
  }

  function test_validPayload() {
    var result = Model.parseCnnPayload(validPayload())
    verify(result.ok)
    compare(result.data.value, 65)
    compare(result.data.classification, "Greed")
    compare(result.data.comparisons.length, 4)
    compare(result.data.comparisons[2].value, 41)
    compare(result.data.comparisons[2].classification, "Fear")
    verify(result.data.sourceTimestamp > 0)
  }

  function test_unknownRatingFallsBackToScore() {
    var result = Model.parseCnnPayload(validPayload({ rating: "unexpected", score: 10 }))
    verify(result.ok)
    compare(result.data.classification, "Extreme Fear")
  }

  function test_optionalComparisonIsOmitted() {
    var result = Model.parseCnnPayload(validPayload({ previous_1_year: null }))
    verify(result.ok)
    compare(result.data.comparisons.length, 3)
  }

  function test_invalidPayloads() {
    verify(!Model.parseCnnPayload("not json").ok)
    verify(!Model.parseCnnPayload("{}").ok)
    verify(!Model.parseCnnPayload(validPayload({ score: 101 })).ok)
    verify(!Model.parseCnnPayload(validPayload({ score: -1 })).ok)
    verify(!Model.parseCnnPayload(validPayload({ timestamp: "not a date" })).ok)
  }

  function test_curlEnvelopeValidation() {
    var ok = Model.curlResult(curlEnvelope(validPayload(), 200, "application/json"), 0)
    verify(ok.ok)

    compare(Model.curlResult(curlEnvelope("blocked", 418, "text/plain"), 22).error,
            "CNN blocked the data request")
    compare(Model.curlResult(curlEnvelope("<html>", 200, "text/html"), 0).error,
            "CNN returned an unexpected response")
    compare(Model.curlResult("", 28).error, "CNN request timed out")
    compare(Model.curlResult("", 63).error, "CNN response was too large")
    verify(Model.curlResult("", 75).conflict)
  }

  function test_cacheRoundTripAndCorruption() {
    var attempted = Model.cacheWithAttempt(Model.emptyCache(), 1000)
    var parsed = Model.parseCnnPayload(validPayload())
    var complete = Model.cacheWithData(attempted, parsed.data, 2000)
    var restored = Model.parseCache(JSON.stringify(complete))
    compare(restored.lastAttemptAt, 1000)
    compare(restored.lastSuccessAt, 2000)
    compare(restored.value, 65)
    compare(restored.comparisons.length, 4)
    compare(Model.parseCache("broken").value, -1)
  }

  function test_refreshTiming() {
    var day = Model.REFRESH_INTERVAL_MS
    compare(Model.refreshDelayMs(0, 1000, day), 0)
    compare(Model.refreshDelayMs(1000, 1000, day), day)
    compare(Model.refreshDelayMs(1000, 1000 + day - 1, day), 1)
    compare(Model.refreshDelayMs(1000, 1000 + day, day), 0)
    verify(!Model.shouldFetch(1000, 1000 + day - 1, day))
    verify(Model.shouldFetch(1000, 1000 + day, day))
    compare(Model.refreshDelayMs(5000, 4000, day), day)
  }
}
