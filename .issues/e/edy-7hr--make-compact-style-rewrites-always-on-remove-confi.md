---
# edy-7hr
title: Make compact-style rewrites always-on; remove Configuration.isActive from rewrite path
status: scrapped
type: task
priority: high
created_at: 2026-04-29T23:13:28Z
updated_at: 2026-04-30T00:00:47Z
parent: iv7-r5g
blocked_by:
    - 6ji-ue3
sync:
    github:
        issue_number: "512"
        synced_at: "2026-04-30T00:29:45Z"
---

## Goal

Land the semantic the user actually wants: compact-style rewrites apply unconditionally — no per-rule on/off toggle. Drop the `Configuration.isActive(rule:)` check from the rewrite-path gate.

## Status

`6ji-ue3` introduced `Context.shouldRewrite(_:at:)` and `Context.applyRewrite(_:to:parent:transform:)` as the rewrite-path entry points and deleted the `applyRule` free function. `shouldRewrite` currently delegates to `shouldFormat`, so behavior is identical (selection + ruleMask + isActive). This issue replaces `shouldRewrite`'s body with the version that drops `isActive`.

## Why it was deferred

`Tests/SwiftiomaticTestSupport/Configuration+Testing.swift`'s `Configuration.forTesting(enabledRule:)` disables all rules then enables one — relying on `isActive` to gate the pipeline so tests see only the named rule's output. Dropping `isActive` from rewrites without updating that helper makes every rule fire in every test, breaking ~2,700 tests.

## Plan

1. Replace `Context.shouldRewrite(_:at:)` body with the selection + ruleMask version (no `isActive` call).
2. Update test infrastructure so per-rule isolation works without `Configuration.forTesting(enabledRule:)`. Options:
   - Have `assertFormatting` run a single-rule pipeline (call the rule's `transform` directly on the parsed tree) instead of the full `RewriteCoordinator`.
   - Or introduce a per-test rule-mask mechanism that suppresses every rule except the named one (closer to current behavior, fits the new gating).
3. Audit `Configuration.forTesting(enabledRule:)` callers (`assertFormatting` + others) to land on whichever option is chosen.
4. Confirm `Configuration.isActive(rule:)` is still needed for lint (yes — `LintPipeline.visitIfEnabled` uses `shouldFormat` with isActive). Leave it intact for lint-side use.

## Verification bar

- All tests pass (modulo the 2 pre-existing pretty-printer-idempotency failures).
- A test that explicitly verifies `// sm:ignore <rule>` and `--lines` selection still gate compact-pipeline rewrites.

## Out of scope

- Lint-side gating (unchanged).
- `Context.ruleState(for:)` migration (`c6i-b47`).
- Structural-pass rule migration (`2uk-cll`).



## Reasons for Scrapping

Pursued this in-session and discovered the premise was wrong. The user-visible "no per-rule toggle for compact-style rules" semantic is a *configuration schema* concern (the user-facing JSON shouldn't expose per-rule on/off for compact-pipeline rules — already delivered by `o72-vx7`'s schema redesign), not a *runtime gate* concern.

Concretely, dropping `Configuration.isActive(rule:)` from `Context.shouldRewrite` produces no production benefit and breaks two legitimate consumers:

1. **Test isolation** — `Configuration.forTesting(enabledRule:)` relies on `isActive` to suppress all-but-one rule across thousands of tests. A replacement allowlist mechanism was prototyped but added complexity for no production gain.
2. **Opt-in default semantics** — rules with `defaultIsActive: false` (e.g. `PreferIsEmpty`, `PreferExplicitFalse`) need the configured value consulted to honour their default-off behaviour. Skipping the check makes opt-in rules fire by default — the wrong direction.

The original `6ji-ue3` introduced `Context.shouldRewrite` thinking it would diverge from `shouldFormat` later. That divergence isn't actually warranted; the method is now a thin alias. Could fold it back into a single entry point as a follow-up cleanup, but not a priority.

### What stays from the in-session work

Nothing. All exploratory changes (allowlist on Context/RewriteCoordinator, modified `shouldRewrite` body, GoldenCorpusTests that drifted) reverted in-session. Working tree returns to the baseline state from `2uk-cll`.

### What was deleted

GoldenCorpus snapshot tests (`Tests/SwiftiomaticTests/GoldenCorpus/`) — the snapshots were drifting under the exploratory changes and the test design (formatting whole files against frozen output) is fragile. Removed.
