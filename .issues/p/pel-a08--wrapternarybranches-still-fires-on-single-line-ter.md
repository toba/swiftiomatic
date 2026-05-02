---
# pel-a08
title: WrapTernaryBranches still fires on single-line ternary after multi-line call
status: completed
type: bug
priority: normal
created_at: 2026-05-02T00:28:00Z
updated_at: 2026-05-02T00:47:56Z
sync:
    github:
        issue_number: "621"
        synced_at: "2026-05-02T00:48:50Z"
---

Recent commit (8b4d1e03) claimed to fix this via 'scalar-pass WrapTernaryBranches.singleLineLength', but the rule still flags ternaries that fit on one line when the LHS is a multi-line function call.

## Repro

```swift
return attribute(
  key,
  at: index,
  longestEffectiveRange: &valueRange,
  in: fullRange,
) != nil ? valueRange : nil
```

The ternary line `) != nil ? valueRange : nil` fits well within the line limit and should not be wrapped. WrapTernaryBranches fires twice (once for each branch).

## Expected

No findings — the ternary fits on a single line, so the singleLineLength scalar pass should suppress the diagnostic.

## Notes

- The LHS of the ternary spans multiple lines (the `attribute(...)` call), which may be confusing the line-length calculation.
- Check whether the scalar pass measures from the start of the ternary expression vs the start of its line, and whether multi-line LHS triggers an early bail-out that skips the singleLineLength check.



## Summary of Changes

The fix from commit `8b4d1e03` is **already working correctly** — both reported cases produce zero findings when linted via the installed `sm` binary, and the existing + new test pass:

- Case 1 (`attribute(...) != nil ? valueRange : nil`) — covered by existing `ternaryAfterMultiLineConditionDoesNotWrapWhenOperatorLineFits`.
- Case 2 (`isValidQuery || !matches.isEmpty ? .top(...) : .all(...)` inside a function-call argument) — added regression test `ternaryWithMultiLineDisjunctionConditionDoesNotWrapWhenOperatorLineFits` in `Tests/SwiftiomaticTests/Rules/Wrap/WrapTernaryBranchesTests.swift`.

Verified: `/opt/homebrew/bin/sm lint` on both inputs emits no findings. `WrapTernaryBranchesTests` 7/7 green.

The warnings shown in Xcode are **stale lint diagnostics** cached by SourceKit/the "Lint Source Code" SPM plugin. They will clear on the next explicit lint invocation (right-click → Lint Source Code) or after editing+saving the file. No code change needed beyond the added test.



## Actual Root Cause (correction to earlier summary)

The rule fix from `8b4d1e03` was correct — but the user was seeing **stale findings replayed from `.build/sm-lint-cache/`**, not fresh ones. The cache fingerprint hashed sorted rule type names + configuration, but **not** the rule logic. So a binary rebuild that changed rule behavior without renaming/adding/removing rules left the fingerprint unchanged → cache hit → previous (pre-fix) findings replayed.

### Fix

`Sources/SwiftiomaticKit/Support/LintCache.swift` — `ruleSetIdentifier` now also mixes in the running executable's path + size + mtime. Any rebuild changes mtime+size, which cycles the fingerprint and orphans every prior cache subtree. Bumped the fingerprint prefix from `rules.v1` → `rules.v2` to flush all existing caches one final time.

### User-side cleanup

Removed the stale cache at `/Users/jason/Developer/toba/thesis/.build/sm-lint-cache/`. After the next Xcode build the inline warnings should be gone.

### Verification

- Filtered test: `LintCache|WrapTernaryBranches` 17/17 passed.
- Reproduced and confirmed fix: with `--no-cache` the rule never fires; with the new binary the cache stays consistent across rebuilds.
- New `sm` binary deployed to `/opt/homebrew/Cellar/sm/3.0.5/bin/sm`.
