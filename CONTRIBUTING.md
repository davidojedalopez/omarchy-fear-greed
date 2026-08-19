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
   qmllint -I /usr/share/omarchy/shell -I . SentimentEffects.qml Panel.qml Model.js
   QT_QPA_PLATFORM=offscreen qmltestrunner -input tests -o -,txt
   qml6 tests/EffectsPreview.qml
   ```

The preview cycles through representative Fear, Neutral, and Greed scores
without reading or writing the production CNN cache. Click the card to advance,
press Space to change animation mode, or use 1–5 to jump to a score band. Pass a
starting score after `--`, for example `qml6 tests/EffectsPreview.qml -- 90`.

CNN's endpoint is unsupported. Changes intended to defeat new blocking
mechanisms will not be accepted. Source failures should degrade to stale cached
data and a clear error.
