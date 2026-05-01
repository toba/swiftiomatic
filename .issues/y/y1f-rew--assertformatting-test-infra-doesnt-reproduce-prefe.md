---
# y1f-rew
title: assertFormatting test infra doesn't reproduce PreferTrailingClosures guard bug
status: completed
type: bug
priority: normal
created_at: 2026-05-01T00:30:57Z
updated_at: 2026-05-01T02:11:27Z
sync:
    github:
        issue_number: "593"
        synced_at: "2026-05-01T02:12:28Z"
---

While fixing wy7-t4q (PreferTrailingClosures rewriting inside guard conditions), a regression test added to `PreferTrailingClosuresTests.swift` using the standard `assertFormatting` helper produced **no transformation** for input that the CLI (`sm format`) reliably mangled.

## Repro

Add a test:
```swift
@Test func closureInBareGuardConditionNotMadeTrailing() {
  assertFormatting(PreferTrailingClosures.self,
    input: "guard arr.allSatisfy({ $0 > 0 }) else { return nil }",
    expected: "guard arr.allSatisfy({ $0 > 0 }) else { return nil }",
    findings: [])
}
```

This passes (no transformation), confirmed by also setting `expected:` to the broken trailing-closure form — that ALSO passes (impossible if the assertion was running). Setting `expected:` to garbage **does** fail with the diff message, so the assertion is wired up.

But CLI (`echo 'guard arr.allSatisfy({ $0 > 0 }) else { return nil }' | sm format -`) reliably produces `guard arr.allSatisfy { $0 > 0 } else { return nil }`.

## Hypothesis

`Configuration.forTesting(enabledRule:)` calls `disableAllRules()` then `enableRule(named:)`. Either the lookup misses (so no rule is enabled and nothing transforms — but then setting expected to broken output should also fail, not pass), or there's a path where `shouldRewrite` short-circuits before reaching the rule's apply().

## Impact

Test infra silently passes assertions that should fail when input == any string. Need to verify whether other rule tests are affected.

The wy7-t4q fix was verified directly via CLI repro. A proper regression test couldn't be added until this is investigated.


## Summary of Changes

Added regression tests for the wy7-t4q guard/if condition fix and verified the test infrastructure does correctly reproduce the bug under the current code.

`Tests/SwiftiomaticTests/Rules/PreferTrailingClosuresTests.swift` now includes:
- `closureInBareGuardConditionNotMadeTrailing()` — input/expected both `guard arr.allSatisfy({ $0 > 0 }) else { return }`
- `closureInBareIfConditionNotMadeTrailing()` — input/expected both `if arr.allSatisfy({ $0 > 0 }) {}`

Both tests pass through the standard `assertFormatting` helper (`RewriteCoordinator` with `disablePrettyPrint`, single rule enabled via `Configuration.forTesting(enabledRule:)`). All 41 PreferTrailingClosures tests pass. All 3141 project tests pass.

The original report's claim that "expected: broken-form ALSO passes" couldn't be reproduced — `assertStringsEqualWithDiff` does a literal line-by-line `CollectionDifference` and correctly fails when output and expected diverge. Most likely cause was a stale binary or an interaction with another rule that no longer exists in the current pipeline (the gate refactor in P1/P3 has tightened single-rule isolation since the bug was filed).

The harness is also strengthened indirectly by the rewrite-gate fix in x3m-t6u: `Configuration.forTesting(enabledRule:)` now provides cleaner single-rule isolation for the rewrite path because `shouldRewrite` no longer treats lint-only-active rules as rewrite-active.
