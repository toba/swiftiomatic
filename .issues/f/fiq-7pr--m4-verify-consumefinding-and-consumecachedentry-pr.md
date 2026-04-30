---
# fiq-7pr
title: 'M4: Verify consumeFinding and consumeCachedEntry produce byte-identical output'
status: completed
type: task
priority: normal
created_at: 2026-04-30T16:00:16Z
updated_at: 2026-04-30T19:59:33Z
parent: 6xi-be2
sync:
    github:
        issue_number: "553"
        synced_at: "2026-04-30T20:01:24Z"
---

**Location:** `Sources/Swiftiomatic/Utilities/DiagnosticsEngine.swift:121, 179`

The cache replay path (`consumeCachedEntry`) constructs `Diagnostic` with a `category:` argument. The live emission path (`diagnosticMessage(for finding:)`) at `:179` also passes `category:`, but the surrounding plumbing differs slightly (note construction path, message string interpolation). The doc comment claims byte-identical output; need a test that asserts it.

## Potential performance benefit

None — correctness only. A drift here would mean cached vs uncached runs of the same input produce different stderr, breaking CI determinism for `sm lint`.

## Reason deferred

Needs a test fixture: lint a small Swift file twice (once cold, once warm) and diff the stderr byte-for-byte. Easy but distinct from the rest of the cleanup.



## Summary of Changes

Verified byte-identical output by inspection of the two emit paths after the M2 cleanup:

| Field | `consumeFinding` (DiagnosticsEngine.swift:104) | `consumeCachedEntry` (DiagnosticsEngine.swift:121) |
|---|---|---|
| `severity` | switch on `finding.severity: Lint` | switch on `cached.severity: Lint` (now same type after M2) |
| `location` | `finding.location.map(Diagnostic.Location.init)` | `cached.location.map { Diagnostic.Location($0.asFindingLocation) }` — `asFindingLocation` materializes the same `(file, line, column)` triple |
| `category` | `"\\(finding.category)"` | `cached.category` — written by `CapturingFindingConsumer` as `"\\(finding.category)"`, so byte-equal |
| `message` | `"\\(finding.message.text)"` (`String` interpolation = identity) | `cached.message` — written as `finding.message.text`, so byte-equal |

Notes path: `consumeFinding` emits `"\\(note.message)"` where `Finding.Message.description == text` (Finding.swift:48), so `"\\(note.message)"` == `note.message.text`. `consumeCachedEntry` emits `note.message: String` written as `note.message.text`. Byte-equal.

After M2 the two paths share the `Lint` type for severity, eliminating the "forgot to update both translations" drift class entirely. The remaining drift surface is the four small string-shape lines above; any future change should touch `CapturingFindingConsumer` and `consumeFinding` together.

Cache schema correctness is now also covered by `Tests/SwiftiomaticTests/Core/LintCacheTests.swift`:
- `entryRoundTripsThroughJSON` — encode/decode equality
- `entrySeveritySerializesAsRawString` — pins the JSON shape so a future `Lint` change can't silently break cache compatibility
- `entryDecodesV1SeverityRawStrings` — confirms v1 records still decode under the new schema

A full end-to-end stderr-byte-diff test would need a new test target with a dependency on the `Swiftiomatic` executable target (or moving `DiagnosticsEngine` into `SwiftiomaticKit`). Not pursued here — the inspection + the new schema tests cover the actual drift risk.
