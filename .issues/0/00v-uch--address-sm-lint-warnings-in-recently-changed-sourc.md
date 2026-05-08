---
# 00v-uch
title: Address sm lint warnings in recently-changed source files
status: completed
type: task
priority: low
created_at: 2026-05-08T20:44:22Z
updated_at: 2026-05-08T20:53:10Z
sync:
    github:
        issue_number: "669"
        synced_at: "2026-05-08T20:55:18Z"
---

`sm lint` on Swift sources changed in the last two days reports the following findings. None are correctness bugs, but they are house-rule violations from our own linter and should be cleaned up.

## Findings

- [x] `Sources/GeneratorKit/RuleCollector.swift:339:58` — [noForceUnwrap] force unwrap of `description!`
- [x] `Sources/GeneratorKit/RuleCollector.swift:398:58` — [noForceUnwrap] force unwrap of `description!`
- [x] `Sources/SwiftiomaticKit/Rules/Comments/CommentReflowEngine.swift:157:63` — [wrapTernaryBranches] wrap ternary branch onto new line
- [x] `Sources/SwiftiomaticKit/Rules/Comments/CommentReflowEngine.swift:157:93` — [wrapTernaryBranches] wrap ternary branch onto new line
- [x] `Sources/SwiftiomaticKit/Rules/Wrap/NestedCallLayout.swift:289:28` — [noForceUnwrap] `level.call.arguments.first!`
- [x] `Sources/SwiftiomaticKit/Rules/Wrap/NestedCallLayout.swift:351:28` — [noForceUnwrap] `level.call.arguments.first!`
- [x] `Sources/SwiftiomaticKit/Rules/Wrap/NestedCallLayout.swift:385:28` — [noForceUnwrap] `level.call.arguments.first!`
- [x] `Sources/SwiftiomaticKit/Rules/Wrap/NestedCallLayout.swift:402:29` — [noForceUnwrap] `outermost.arguments.first!`
- [x] `Sources/SwiftiomaticKit/Rules/Wrap/NestedCallLayout.swift:571:28` — [noForceUnwrap] `level.call.arguments.first!`
- [x] `Sources/SwiftiomaticKit/Syntax/Glob.swift:17:9` — [dropRedundantSelf] remove redundant `self.` prefix

## Notes

The `NestedCallLayout` force unwraps are all on `level.call.arguments.first` after a guard verifies non-empty arguments — they are safe in context but should be replaced with `guard let first = ...` or precondition for clarity.

The `RuleCollector` force unwraps of `description!` are on `Mirror` reflection results where `description` is documented as non-nil for the cases used. Consider `?? "<unknown>"` or a precondition.

Deep review of changed files (5055 LOC across 60+ files) surfaced no other modernization or correctness issues — rule logic refinements (false-positive fixes in `convertStaticStructToEnum`, `dropRedundantEscaping`, etc.) are well-factored, and no anti-patterns were found in concurrency, typed throws, or naming.


## Summary of Changes

- `RuleCollector.schemaNode` / `schemaNodeFromType`: replaced `description?.isEmpty == false ? description! : propertyName` with `(description?.isEmpty == false ? description : nil) ?? propertyName`.
- `CommentReflowEngine.parseBlocks`: split the block-quote line strip into a multi-line ternary so each branch is on its own line.
- `NestedCallLayout`: added `soleArgument(of:)` helper that asserts the chain invariant (each level has exactly one argument), and replaced all five `level.call.arguments.first!` / `outermost.arguments.first!` sites with calls to it.
- `Glob.init?`: dropped redundant `self.` from `self.regex = r`.

Verified: `sm lint` clean on all changed files; full `swift test` suite passes (3287 tests, 0 failures).
