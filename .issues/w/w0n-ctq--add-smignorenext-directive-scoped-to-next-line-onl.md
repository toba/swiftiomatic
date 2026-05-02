---
# w0n-ctq
title: Add sm:ignore:next directive scoped to next line only
status: completed
type: feature
priority: normal
created_at: 2026-05-02T00:32:08Z
updated_at: 2026-05-02T00:35:00Z
sync:
    github:
        issue_number: "620"
        synced_at: "2026-05-02T00:48:50Z"
---

Add a new ignore directive form: `// sm:ignore:next <rules>` that applies only to the next statement/member, not from the comment to EOF.

## Tasks
- [x] Add tests in RuleMaskTests for the new `:next` form
- [x] Update regex in RuleStatusCollectionVisitor to capture optional `:next` scope
- [x] When directive has `:next` scope, record nodeRange instead of restOfFileRange
- [x] Update doc comment in RuleMask.swift
- [x] Verify full test suite passes


## Summary of Changes

- New directive form `// sm:ignore:next [rules]` applies the ignore only to the immediately following statement or member, instead of extending to EOF.
- Updated regex in `RuleStatusCollectionVisitor` to capture optional `:next` scope; threaded scope through to range selection in `applyDirectives` (uses `nodeRange` for `:next`, `restOfFileRange` otherwise).
- Updated `isFormatterIgnorePresent` in `CommentMovingRewriter` to also recognize the bare `// sm:ignore:next` form for skipping pretty-printing of the next node.
- Added 4 new tests covering `:next` with rule names, bare `:next`, multi-line statement scope, and member scope.
- Updated `RuleMask.swift` doc comment to describe the three forms.
- Full test suite (3179 tests) passes.
