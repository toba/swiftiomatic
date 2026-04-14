---
# ze0-gnc
title: Rule toggles unresponsive for format rules; INDENT option not saved
status: review
type: bug
priority: normal
created_at: 2026-04-14T01:48:36Z
updated_at: 2026-04-14T01:49:26Z
sync:
    github:
        issue_number: "263"
        synced_at: "2026-04-14T02:00:50Z"
---

Three related bugs in the SwiftiomaticApp:

## Problems

1. **UserDefaults suite name mismatch** — `SharedDefaults.suiteName` is `"app.toba.swiftiomatic"` but the app group entitlement is `"group.app.toba.swiftiomatic"`. In a sandboxed app, `UserDefaults(suiteName:)` requires the app group name. This causes `suite` to return `nil`, so `save()` silently fails with "Could not open UserDefaults suite". No config changes are persisted.

2. **Toggle guard blocks format/suggest rules** — `ConfigStore.toggleRule()` has `guard entry.scope == .lint else { return }`, so clicking the toggle on a format rule like `switch_case_alignment` does nothing. Combined with `isRuleEnabled()` always returning `true` for format/suggest, the toggle blinks and snaps back.

3. **INDENT option appears not to work** — consequence of bug 1: the `indented_cases: true` option is set in memory but never persisted to UserDefaults, so the Xcode extension never sees it.

## Tasks

- [x] Fix `SharedDefaults.suiteName` to `"group.app.toba.swiftiomatic"` in both app and extension
- [x] Update `ConfigStore.isRuleEnabled` to check `disabledLintRules` for format/suggest rules
- [x] Remove scope guard from `ConfigStore.toggleRule` so format/suggest rules can be toggled
- [x] Build and verify


## Summary of Changes

Three fixes in three files:

1. **SharedDefaults.swift** (both app and extension) — suite name changed from `"app.toba.swiftiomatic"` to `"group.app.toba.swiftiomatic"` to match the app group entitlement. This was causing `UserDefaults(suiteName:)` to return nil in the sandbox, silently preventing all config saves.
2. **ConfigStore.swift** — `isRuleEnabled()` now checks `disabledLintRules` for all scopes (not just lint). Removed scope guard from `toggleRule()` so format/suggest rules can be toggled off/on.
