---
# bmo-7x5
title: DropRedundantSelf strips required self in @autoclosure @escaping argument
status: completed
type: bug
priority: normal
created_at: 2026-05-02T16:16:12Z
updated_at: 2026-05-02T16:22:18Z
sync:
    github:
        issue_number: "630"
        synced_at: "2026-05-02T17:32:31Z"
---

## Repro

\`\`\`swift
private extension Document {
    func saveCitationGroup(_ action: SaveCitationGroup) {
        if action.documentType != type { return }

        withErrorLoggingTask(
            "Failed to save citation group \(action.id) for \(self.type) document",
            priority: .userInitiated,
        ) {
            try await self.update(citationGroup: action)
        }
    }
}
\`\`\`

\`Document\` is a class. \`withErrorLoggingTask\`'s message parameter is \`@autoclosure @escaping () -> String\`. The string literal (with its \`\\(self.type)\` interpolation) is wrapped by the compiler into an implicit escaping closure on a reference type, so Swift requires \`self.\` there.

DropRedundantSelf strips it, producing:

\`\`\`
"Failed to save citation group \(action.id) for \(type) document"
\`\`\`

Compiler error: *"Reference to property 'type' in closure requires explicit use of 'self' to make capture semantics explicit."*

## Cause

The rule operates purely on syntax. It cannot tell that an argument expression will be wrapped in an implicit escaping autoclosure — that requires type-checker information. In a reference-type context (class/actor/extension-of-class), implicit-self is currently allowed for any argument expression at the call site, even though the parameter may be \`@autoclosure @escaping\` and reject it.

## Tasks

- [x] Add a failing test covering \`@autoclosure @escaping\` parameter (and string interpolation in such arguments)
- [x] Decide on the conservative fix. Chose option: skip stripping inside string interpolation segments that appear directly as a function-call argument, on reference types only.
  - Skip stripping inside any function-call argument when the enclosing type is a reference type. Likely too aggressive — many trivial \`logger("\\(self.foo)")\` callers are non-escaping.
  - Skip stripping inside string interpolation segments that appear directly as a function-call argument. Narrow heuristic; covers the common logger / error-message pattern.
  - Skip stripping inside any expression that is a direct function-call argument in a reference-type context. Aggressive but matches the SE-0269 risk surface.
- [x] Implement the chosen heuristic in \`Sources/SwiftiomaticKit/Rules/Redundancies/DropRedundantSelf.swift\`
- [x] Confirm full test suite still passes (3192 passed)

## Notes

This is a known SE-0269 limitation that any source-only redundant-self analyzer faces (SwiftLint, SwiftFormat have similar caveats). Without type info, we must be conservative on reference types.



## Summary of Changes

- `DropRedundantSelf.transform` now skips removal when the `self.<member>` access sits inside a string interpolation whose enclosing string literal is a direct function-call argument, **and** the enclosing type is a reference type. Walk halts at any enclosing `ClosureExprSyntax` so genuine closure-body interpolations still strip when self is captured.
- Value-type contexts are unaffected (autoclosure capture is not a problem there).
- Per-occurrence override remains via `// sm:ignore`.
- New tests: `keepSelfInsideStringInterpolationOfFunctionCallArg`, `removeRedundantSelfInsideStringInterpolationInValueType`, `keepSelfInAutoclosureArgumentInterpolationOnReferenceType`.
- Old `removeRedundantSelfInsideStringInterpolation` test (which encoded the buggy behavior) replaced.

### Files
- `Sources/SwiftiomaticKit/Rules/Redundancies/DropRedundantSelf.swift`
- `Tests/SwiftiomaticTests/Rules/DropRedundantSelfTests.swift`
