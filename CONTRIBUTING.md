# Contributing

Bug reports and focused pull requests are welcome.

Before opening a pull request:

1. Keep every network destination and process argument fixed and reviewable.
2. Do not add credentials, telemetry, privileges, services, installers, or
   remote-code execution.
3. Preserve the one-attempt-per-24-hours rule across restarts and monitors.
4. Add or update model tests for parsing, cache, and scheduling changes.
5. Run the checks below on Omarchy 4:

   ```bash
   omarchy plugin validate .
   qmllint -I /usr/share/omarchy/shell -I . FireBed.qml GreedRain.qml SentimentEffects.qml Panel.qml Model.js
   /usr/lib/qt6/bin/qsb --qt6 --qsbversion 64 -o shaders/flame-warp.frag.qsb shaders/flame-warp.frag
   QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests -o -,txt
   qml6 tests/EffectsPreview.qml
   ```

The preview cycles through representative Fear, Neutral, and Greed scores
without reading or writing the production CNN cache. Click the card to advance,
press Space to change animation mode, or use 1–6 to jump to a score band. Pass a
starting score after `--`, for example `qml6 tests/EffectsPreview.qml -- 90`.
For an isolated capture, add `--capture=/tmp/fear-greed.png`; the preview saves
the gauge card after 1.2 seconds and exits.

CNN's endpoint is unsupported. Changes intended to defeat new blocking
mechanisms will not be accepted. Source failures should degrade to stale cached
data and a clear error.
