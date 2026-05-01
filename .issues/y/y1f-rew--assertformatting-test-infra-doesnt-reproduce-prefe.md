---
# y1f-rew
title: assertFormatting test infra doesn't reproduce PreferTrailingClosures guard bug
status: ready
type: bug
priority: normal
created_at: 2026-05-01T00:30:57Z
updated_at: 2026-05-01T00:30:57Z
sync:
    github:
        issue_number: "593"
        synced_at: "2026-05-01T00:49:16Z"
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
