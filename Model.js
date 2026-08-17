.pragma library

var CACHE_SCHEMA_VERSION = 1
var REFRESH_INTERVAL_MS = 24 * 60 * 60 * 1000
var RESPONSE_MARKER = "\n__OMARCHY_FEAR_GREED_META__:"

function emptyCache() {
  return {
    schemaVersion: CACHE_SCHEMA_VERSION,
    lastAttemptAt: 0,
    lastSuccessAt: 0,
    sourceTimestamp: 0,
    value: -1,
    classification: "",
    comparisons: []
  }
}

function normalizedScore(value) {
  if (value === undefined || value === null || value === "") return -1
  var number = Number(value)
  if (!isFinite(number) || number < 0 || number > 100) return -1
  return Math.round(number)
}

function classificationForValue(score) {
  var value = normalizedScore(score)
  if (value < 0) return ""
  if (value <= 24) return "Extreme Fear"
  if (value <= 44) return "Fear"
  if (value <= 55) return "Neutral"
  if (value <= 74) return "Greed"
  return "Extreme Greed"
}

function canonicalClassification(value, fallbackScore) {
  var key = String(value || "").trim().toLowerCase()
  var labels = {
    "extreme fear": "Extreme Fear",
    "fear": "Fear",
    "neutral": "Neutral",
    "greed": "Greed",
    "extreme greed": "Extreme Greed"
  }
  return labels[key] || classificationForValue(fallbackScore)
}

function colorForValue(score) {
  var value = normalizedScore(score)
  if (value < 0) return "#a1a1aa"
  if (value <= 24) return "#ef4444"
  if (value <= 44) return "#f97316"
  if (value <= 55) return "#eab308"
  if (value <= 74) return "#84cc16"
  return "#22c55e"
}

function comparison(label, value) {
  var score = normalizedScore(value)
  if (score < 0) return null
  return {
    label: label,
    value: score,
    classification: classificationForValue(score)
  }
}

function parseCnnPayload(raw) {
  try {
    var payload = JSON.parse(String(raw || ""))
    var current = payload && payload.fear_and_greed ? payload.fear_and_greed : null
    if (!current) return { ok: false, error: "CNN returned no index data" }

    var value = normalizedScore(current.score)
    if (value < 0) return { ok: false, error: "CNN returned an invalid index value" }

    var sourceTimestamp = Date.parse(String(current.timestamp || ""))
    if (!isFinite(sourceTimestamp) || sourceTimestamp <= 0)
      return { ok: false, error: "CNN returned an invalid update time" }

    var candidateRows = [
      comparison("Previous close", current.previous_close),
      comparison("1 week ago", current.previous_1_week),
      comparison("1 month ago", current.previous_1_month),
      comparison("1 year ago", current.previous_1_year)
    ]
    var rows = []
    for (var i = 0; i < candidateRows.length; i++) {
      if (candidateRows[i]) rows.push(candidateRows[i])
    }

    return {
      ok: true,
      data: {
        sourceTimestamp: sourceTimestamp,
        value: value,
        classification: canonicalClassification(current.rating, value),
        comparisons: rows
      }
    }
  } catch (error) {
    return { ok: false, error: "CNN returned invalid JSON" }
  }
}

function parseCurlOutput(raw) {
  var text = String(raw || "")
  var markerIndex = text.lastIndexOf(RESPONSE_MARKER)
  if (markerIndex < 0) return { body: text, status: 0, contentType: "" }

  var metadata = text.slice(markerIndex + RESPONSE_MARKER.length).trim().split("|")
  var status = Number(metadata[0])
  return {
    body: text.slice(0, markerIndex),
    status: isFinite(status) ? status : 0,
    contentType: String(metadata.length > 1 ? metadata.slice(1).join("|") : "").trim().toLowerCase()
  }
}

function curlResult(raw, exitCode) {
  var response = parseCurlOutput(raw)
  var code = Number(exitCode)

  if (code === 75) return { ok: false, conflict: true, error: "" }
  if (response.status === 418) return { ok: false, error: "CNN blocked the data request" }
  if (code === 28) return { ok: false, error: "CNN request timed out" }
  if (code === 6 || code === 7) return { ok: false, error: "Could not reach CNN" }
  if (code === 60) return { ok: false, error: "CNN TLS verification failed" }
  if (code === 63) return { ok: false, error: "CNN response was too large" }
  if (code !== 0) return { ok: false, error: "Could not update the index" }
  if (response.status !== 200) return { ok: false, error: "CNN returned HTTP " + response.status }
  if (response.contentType.indexOf("application/json") !== 0)
    return { ok: false, error: "CNN returned an unexpected response" }

  return parseCnnPayload(response.body)
}

function normalizedComparisons(value) {
  var input = Array.isArray(value) ? value : []
  var result = []
  for (var i = 0; i < input.length && result.length < 4; i++) {
    var item = input[i]
    if (!item || typeof item !== "object") continue
    var score = normalizedScore(item.value)
    var label = String(item.label || "")
    if (score < 0 || label === "") continue
    result.push({
      label: label,
      value: score,
      classification: classificationForValue(score)
    })
  }
  return result
}

function normalizeCache(value) {
  var result = emptyCache()
  if (!value || typeof value !== "object" || Number(value.schemaVersion) !== CACHE_SCHEMA_VERSION)
    return result

  var lastAttemptAt = Number(value.lastAttemptAt)
  var lastSuccessAt = Number(value.lastSuccessAt)
  var sourceTimestamp = Number(value.sourceTimestamp)
  result.lastAttemptAt = isFinite(lastAttemptAt) && lastAttemptAt > 0 ? lastAttemptAt : 0
  result.lastSuccessAt = isFinite(lastSuccessAt) && lastSuccessAt > 0 ? lastSuccessAt : 0
  result.sourceTimestamp = isFinite(sourceTimestamp) && sourceTimestamp > 0 ? sourceTimestamp : 0
  result.value = normalizedScore(value.value)
  result.classification = result.value >= 0
    ? canonicalClassification(value.classification, result.value) : ""
  result.comparisons = result.value >= 0 ? normalizedComparisons(value.comparisons) : []
  return result
}

function parseCache(raw) {
  try {
    var text = String(raw || "").trim()
    return text === "" ? emptyCache() : normalizeCache(JSON.parse(text))
  } catch (error) {
    return emptyCache()
  }
}

function cacheWithAttempt(cache, timestamp) {
  var result = normalizeCache(cache)
  var now = Number(timestamp)
  result.lastAttemptAt = isFinite(now) && now > 0 ? now : 0
  return result
}

function cacheWithData(cache, data, timestamp) {
  var result = normalizeCache(cache)
  var normalized = data && typeof data === "object" ? data : {}
  var value = normalizedScore(normalized.value)
  var now = Number(timestamp)
  if (value < 0 || !isFinite(now) || now <= 0) return result

  result.lastSuccessAt = now
  result.sourceTimestamp = Number(normalized.sourceTimestamp)
  result.value = value
  result.classification = canonicalClassification(normalized.classification, value)
  result.comparisons = normalizedComparisons(normalized.comparisons)
  return result
}

function hasData(cache) {
  return normalizeCache(cache).value >= 0
}

function refreshDelayMs(lastAttemptAt, now, interval) {
  var attempted = Number(lastAttemptAt)
  var current = Number(now)
  var ttl = Number(interval)
  if (!isFinite(ttl) || ttl <= 0) ttl = REFRESH_INTERVAL_MS
  if (!isFinite(attempted) || attempted <= 0) return 0
  if (!isFinite(current) || current <= 0 || current < attempted) return ttl
  return Math.max(0, ttl - (current - attempted))
}

function shouldFetch(lastAttemptAt, now, interval) {
  return refreshDelayMs(lastAttemptAt, now, interval) === 0
}

