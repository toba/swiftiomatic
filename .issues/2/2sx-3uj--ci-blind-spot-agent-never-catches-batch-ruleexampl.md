---
# 2sx-3uj
title: 'CI blind spot: agent never catches batch RuleExampleTests failures'
status: completed
type: bug
priority: high
created_at: 2026-04-13T00:51:01Z
updated_at: 2026-04-13T00:54:17Z
sync:
    github:
        issue_number: "255"
        synced_at: "2026-04-13T00:55:41Z"
---

## Problem

18 consecutive CI failures (v0.18.4 through v0.26.0) since Apr 11. Agent repeatedly claims "all tests pass" before commits, but CI fails every time. This is the third occurrence of this pattern (previously investigated in l3v-pn5 and kli-m0h).

## Root Cause: Agent Never Catches Batch Test Failures

The failure cycle:

1. Agent adds/modifies rules with buggy examples
2. Agent runs **individual** rule tests via xc-mcp → **pass** (each rule only tests its own examples)
3. Agent reports "all tests pass", user commits
4. CI runs `RuleExampleTests` batch (all ~290 rules) → **fail**
5. Agent investigates next session, misidentifies as "test pollution" or "shared state" because Swift Testing misattributes failures to the wrong rule (kli-m0h)
6. Eventually finds genuine rule bugs, fixes, claims victory
7. Next session, new rules added with new bugs, cycle repeats

The kli-m0h workaround (adding `[ruleID]` to `#expect` messages) solved identification in CI logs, but didn't prevent the agent from committing broken code — because the agent never runs the batch test locally or checks CI after commits.

## Current Failures (v0.26.0)

Three rule example bugs confirmed in CI logs and reproducible locally in batch:

### 1. `empty_braces` linebreak style — wrong trivia model

`hasLinebreakWithIndentation` (line 131) and `targetTrivia` (line 217) assume the newline between `{` and `}` lives in `leftBrace.trailingTrivia`. SwiftSyntax puts it in `rightBrace.leadingTrivia`.

- **Detection**: `leftBrace.trailingTrivia == [.newlines(1)]` is always false → non-triggering linebreak examples produce violations
- **Correction**: sets BOTH `leftBrace.trailingTrivia = \n` AND `rightBrace.leadingTrivia = \n` → produces `{\n\n}` (blank line) instead of `{\n}`
- **Fix**: change detection to `leftBrace.trailingTrivia.isEmpty`, change correction to `(Trivia(), rightTrivia)`
- **File**: `Sources/SwiftiomaticKit/Rules/Redundancy/Expressions/EmptyBracesRule.swift`

### 2. `fully_indirect_enum` — trivia transfer overwrites indentation

Rewriter (line 74-93) always transfers `indirect`'s leading trivia to the first remaining modifier. When `indirect` is NOT the first modifier (e.g., `internal indirect case`), this overwrites `internal`'s `\n    ` leading trivia with `indirect`'s (empty or space), producing `{internal case` on one line.

- **Fix**: only transfer trivia when `indirect` is the first modifier in the list
- **File**: `Sources/SwiftiomaticKit/Rules/Redundancy/Modifiers/FullyIndirectEnumRule.swift`

### 3. `no_labels_in_case_patterns` — non-triggering example IS a violation

Non-triggering example `case .pair(first: let x, second: let second)` has label `second` matching variable `second`, which the rule correctly flags as redundant. This should be a triggering example or changed to use a non-matching variable name.

- **Fix**: change `second: let second` to `second: let y` in the non-triggering example
- **File**: `Sources/SwiftiomaticKit/Rules/Redundancy/Syntax/NoLabelsInCasePatternsRule+examples.swift`

## CI Timeline

| Version range | Failure cause | Notes |
|---|---|---|
| v0.18.4–v0.20.0 | Xcode 26.3 (Swift 6.2.4), needs 6.3 | Fixed in v0.21.1 by selecting Xcode_26.4 |
| v0.21.0–v0.22.0 | SIGABRT (signal 6) on SourceKit init | SourceKit disabled for testing, but crashes persist |
| v0.22.1–v0.24.1 | SIGBUS (signal 10), some test failures | `clearCaches()` added between test cases |
| v0.25.0–v0.26.0 | 3 rule example bugs + SIGBUS | Current state — bugs confirmed in CI logs |

## Process Fix Needed

The agent must verify the **batch** test passes before declaring success. Options:

1. **Run `RuleExampleTests` batch after any rule change** — not just individual rules
2. **Check CI status after push** — `gh run watch` or equivalent
3. **Add a pre-commit hook** that runs the batch test (expensive but reliable)
4. **CLAUDE.md instruction**: "After modifying any rule, run the full RuleExampleTests batch, not just the individual rule test"

## Tasks

- [x] Fix empty_braces linebreak trivia (EmptyBracesRule.swift)
- [x] Fix fully_indirect_enum trivia transfer (FullyIndirectEnumRule.swift)
- [x] Fix no_labels_in_case_patterns example (NoLabelsInCasePatternsRule+examples.swift)
- [x] Verify batch test passes locally
- [x] Add CLAUDE.md instruction requiring batch test after rule changes


## Summary of Changes

Fixed 3 rule example bugs, verified batch test passes, added CLAUDE.md instruction to prevent recurrence.
