import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "io.github.davidojedalopez.fear-greed"

  readonly property string sourceUrl: "https://edition.cnn.com/markets/fear-and-greed"
  readonly property string feedUrl: "https://production.dataviz.cnn.io/index/fearandgreed/graphdata"
  readonly property string cacheBase: Quickshell.env("XDG_CACHE_HOME") !== ""
    ? Quickshell.env("XDG_CACHE_HOME") : Quickshell.env("HOME") + "/.cache"
  readonly property string cacheDir: cacheBase + "/omarchy/plugins/" + moduleName
  readonly property string cachePath: cacheDir + "/state.json"
  readonly property string lockPath: cacheDir + "/fetch.lock"
  readonly property int refreshIntervalMs: Model.REFRESH_INTERVAL_MS

  property var cacheState: Model.emptyCache()
  property bool cacheDirReady: false
  property bool cacheLoaded: false
  property bool loading: false
  property string errorText: ""

  readonly property bool hasData: Model.hasData(cacheState)
  readonly property int value: hasData ? cacheState.value : -1
  readonly property string classification: hasData ? cacheState.classification : ""
  readonly property double sourceTimestamp: hasData ? cacheState.sourceTimestamp : 0
  readonly property var comparisons: hasData ? cacheState.comparisons : []
  readonly property bool stale: hasData && cacheState.lastSuccessAt > 0
    && Date.now() - cacheState.lastSuccessAt >= refreshIntervalMs
  readonly property color sentimentColor: Model.colorForValue(value)
  readonly property string displayText: hasData ? ("\u25CF  " + value) : (loading ? "\u25CF  …" : "\u25CF  --")
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true : false

  function colorForValue(score) {
    return Model.colorForValue(score)
  }

  function openSource() {
    Qt.openUrlExternally(sourceUrl)
  }

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function togglePanel() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  function updatedLabel() {
    if (!sourceTimestamp) return "Waiting for the first update"
    var label = "Updated " + Qt.formatDateTime(new Date(sourceTimestamp), "d MMM, HH:mm")
    return stale ? label + " · stale" : label
  }

  function persistCache() {
    if (!cacheDirReady) return
    cacheFile.setText(JSON.stringify(cacheState, null, 2) + "\n")
  }

  function applyCache(state) {
    cacheState = Model.normalizeCache(state)
  }

  function loadCache(raw) {
    applyCache(Model.parseCache(raw))
    cacheLoaded = true
    scheduleNextAttempt()
  }

  function scheduleNextAttempt() {
    refreshTimer.stop()
    if (!cacheDirReady || !cacheLoaded || loading) return

    var delay = Model.refreshDelayMs(cacheState.lastAttemptAt, Date.now(), refreshIntervalMs)
    if (delay <= 0) {
      Qt.callLater(root.maybeFetch)
      return
    }
    refreshTimer.interval = Math.max(1000, Math.ceil(delay))
    refreshTimer.start()
  }

  function maybeFetch() {
    if (!cacheDirReady || !cacheLoaded || loading || fetchProcess.running) return
    if (!Model.shouldFetch(cacheState.lastAttemptAt, Date.now(), refreshIntervalMs)) {
      scheduleNextAttempt()
      return
    }

    cacheState = Model.cacheWithAttempt(cacheState, Date.now())
    persistCache()
    loading = true
    errorText = ""
    fetchProcess.running = true
  }

  function finishFetch(exitCode) {
    loading = false
    var result = Model.curlResult(responseCollector.text, exitCode)
    if (result.conflict) {
      cacheReloadTimer.restart()
      return
    }

    if (result.ok) {
      cacheState = Model.cacheWithData(cacheState, result.data, Date.now())
      errorText = ""
      persistCache()
    } else {
      errorText = result.error || "Could not update the index"
    }
    scheduleNextAttempt()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Component.onCompleted: ensureCacheDir.running = true

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  Process {
    id: ensureCacheDir
    command: ["mkdir", "-p", "--", root.cacheDir]
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.errorText = "Could not create the local cache"
        return
      }
      root.cacheDirReady = true
      cacheFile.reload()
    }
  }

  FileView {
    id: cacheFile
    path: root.cacheDirReady ? root.cachePath : ""
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadCache(text())
    onLoadFailed: root.loadCache("")
    onFileChanged: reload()
  }

  Process {
    id: fetchProcess
    command: [
      "flock", "--nonblock", "--conflict-exit-code", "75", root.lockPath,
      "curl", "--silent", "--show-error", "--fail-with-body",
      "--proto", "=https", "--tlsv1.2",
      "--connect-timeout", "5", "--max-time", "10",
      "--retry", "0", "--max-redirs", "0", "--max-filesize", "524288",
      "--user-agent", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/139.0.0.0 Safari/537.36",
      "--header", "Accept: application/json",
      "--referer", root.sourceUrl,
      "--write-out", Model.RESPONSE_MARKER + "%{http_code}|%{content_type}",
      root.feedUrl
    ]
    stdout: StdioCollector {
      id: responseCollector
      waitForEnd: true
    }
    stderr: StdioCollector {
      waitForEnd: true
    }
    onExited: function(exitCode) { root.finishFetch(exitCode) }
  }

  Timer {
    id: refreshTimer
    repeat: false
    onTriggered: root.maybeFetch()
  }

  Timer {
    id: cacheReloadTimer
    interval: 1500
    repeat: false
    onTriggered: cacheFile.reload()
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.displayText
    foreground: root.hasData ? root.sentimentColor
      : (root.bar ? root.bar.barForeground : Color.foreground)
    fontSize: Style.font.body
    fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
    tooltipText: root.hasData
      ? ("Market Fear & Greed: " + root.value + " · " + root.classification)
      : (root.errorText || "Loading Market Fear & Greed")
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.openSource()
      else if (buttonCode === Qt.LeftButton) root.togglePanel()
    }
  }
}

