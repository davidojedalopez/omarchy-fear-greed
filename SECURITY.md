# Security policy

## Supported version

Security fixes are applied to the latest release on `main`.

## Reporting a vulnerability

Please use GitHub's private vulnerability reporting for this repository. Do
not post credentials, exploit details, private data, or sensitive system
information in a public issue.

Include the affected plugin version, Omarchy version, relevant log lines with
private data removed, and the minimum safe reproduction steps.

## Runtime boundary

Omarchy plugins execute as unsandboxed code inside the long-running
`omarchy-shell` process. Review the repository before installing it.

This plugin:

- invokes only fixed `mkdir`, `flock`, and `curl` commands;
- contacts only CNN's fixed HTTPS data endpoint;
- opens only CNN's fixed public source page;
- accepts no command, URL, file path, or header from users or remote data;
- uses no `sudo`, `pkexec`, shell interpreter, package manager, installer,
  service, bundled executable, listener, telemetry, or analytics;
- handles no credentials or other secrets; and
- caches only normalized public index data and timestamps.

The HTTP response is bounded to 512 KiB and must be a successful JSON response
with valid 0–100 scores and a parseable source timestamp. User-facing errors
are selected from fixed messages rather than exposing raw process output.

## Known source risk

CNN's feed is undocumented and browser-gated. The plugin includes a browser-like
user agent and CNN referrer because ordinary API requests currently receive
HTTP 418. CNN may block, alter, or remove the endpoint at any time. This is an
availability and rights risk, not a claim that the integration is supported.

The plugin limits itself to one request attempt per rolling 24 hours and keeps
the last valid cached reading. It must not be changed to add proxies, rotating
identities, CAPTCHA bypasses, or progressively stronger bot-evasion behavior.

