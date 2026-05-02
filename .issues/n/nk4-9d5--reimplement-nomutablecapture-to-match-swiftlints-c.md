---
# nk4-9d5
title: Reimplement noMutableCapture to match SwiftLint's CaptureVariableRule semantics
status: completed
type: feature
priority: normal
created_at: 2026-05-02T03:48:37Z
updated_at: 2026-05-02T03:51:57Z
sync:
    github:
        issue_number: "627"
        synced_at: "2026-05-02T04:22:41Z"
---

Invert the rule to flag explicit [var] capture-list entries (matching SwiftLint's CaptureVariableRule), instead of implicit references. Rationale: SwiftLint's stance — that listing a mutable var in a capture list is the confusing form — is the upstream community standard. Our current implicit-flag direction has been chasing unbounded false positives because we lack USR-based semantic resolution.

- [x] Rewrite NoMutableCapture.swift to walk ClosureCaptureClauseSyntax and flag mutable-var entries
- [x] Skip weak/unowned, [x = expr] initializer, and self
- [x] Keep MutableVarNameCollector with existing exclusions (lazy, IUO, member-block, attributed)
- [x] Update Finding.Message to reflect new semantics
- [x] Rewrite existing test fixtures from implicit-reference patterns to explicit-capture-list patterns
- [x] Verify full suite passes

## Summary of Changes

Replaced `NoMutableCapture` (implicit-reference flag, ~290 LoC) with `NoMutableInCaptureList` (~75 LoC), matching SwiftLint's `CaptureVariableRule` semantics.

`Sources/SwiftiomaticKit/Rules/Closures/NoMutableCapture.swift` deleted. `Sources/SwiftiomaticKit/Rules/Closures/NoMutableInCaptureList.swift` added: walks `ClosureCaptureClauseSyntax`, checks each entry's name against the file-level mutable-var set. Skips `weak`/`unowned`, `[x = expr]` rebindings, and `self`. Pre-scan exclusions retained: `lazy var`, IUO, member-block stored properties, attributed property-wrapper bindings.

`Tests/SwiftiomaticTests/Rules/NoMutableCaptureTests.swift` deleted. `Tests/SwiftiomaticTests/Rules/NoMutableInCaptureListTests.swift` added with 14 tests covering: explicit/multiple captures flagged, implicit references not flagged, explicit rebinding, weak/unowned, self, let bindings, IUO, lazy, stored property, attributed var, nested closure, Sendable hand-off pattern.

Full test suite: 3190 passed, 0 failed.
