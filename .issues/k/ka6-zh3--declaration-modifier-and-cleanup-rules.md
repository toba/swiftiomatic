---
# ka6-zh3
title: Declaration, modifier, and cleanup rules
status: completed
type: feature
priority: normal
created_at: 2026-04-14T03:18:17Z
updated_at: 2026-04-14T16:19:58Z
parent: 77g-8mh
sync:
    github:
        issue_number: "287"
        synced_at: "2026-04-14T06:15:35Z"
---

Port remaining declaration, modifier, access-control, and cleanup rules from SwiftFormat.

**Implementation**: Mixed `SyntaxLintRule` and `SyntaxFormatRule`. Modifier ordering needs a canonical order configuration option. Unused-code detection may need cross-file analysis (two-pass). Some extend existing Swiftiomatic rules.

## Rules

- [x] `emptyBraces` — Remove whitespace inside empty braces (e.g. `{ }` → `{}`)
- [x] `emptyExtensions` — Remove empty, non-protocol-conforming extensions
- [x] `extensionAccessControl` — Configure extension ACL placement *(extend existing `NoAccessLevelOnExtensionDeclaration`)*
- [x] `fileMacro` — Prefer `#file` or `#fileID` consistently (same behavior in Swift 6+)
- [x] `hoistPatternLet` — Reposition `let`/`var` in patterns *(extend existing `UseLetInEveryBoundCaseVariable` + `NoLabelsInCasePatterns`)*
- [x] `initCoderUnavailable` — Add `@available(*, unavailable)` to required `init(coder:)` without implementation
- [x] `modifierOrder` — Enforce consistent ordering for declaration modifiers (e.g. `public static func` not `static public func`)
- [x] `modifiersOnSameLine` — Ensure all modifiers are on the same line as the declaration keyword
- [x] `noExplicitOwnership` — Remove explicit `borrowing`/`consuming` modifiers
- [x] `preferExplicitFalse` — Prefer `== false` over `!` prefix negation
- [x] `preferFinalClasses` — Prefer `final class` unless designed for subclassing
- [x] `privateStateVariables` — Add `private` to `@State` properties without explicit access control
- [x] `propertyTypes` — ~~Configure inferred vs explicit property types~~ → moved to c7r-77o (too complex)
- [x] `strongOutlets` — Remove `weak` from `@IBOutlet` properties
- [x] `trailingClosures` — ~~Use trailing closure syntax~~ → moved to c7r-77o (too complex)
- [x] `unusedArguments` — ~~Mark unused function arguments~~ → moved to c7r-77o (too complex)
- [x] `unusedPrivateDeclarations` — ~~Remove unused private declarations~~ → moved to c7r-77o (too complex)
- [x] `urlMacro` — ~~Replace URL(string:)! with #URL~~ → moved to c7r-77o (needs config)



## Summary of Changes

Ported 4 new format rules from SwiftFormat:

- **PreferExplicitFalse** (opt-in) — Replaces `!expr` with `expr == false`. Skips #if conditions, comparison/casting operators, double negation. 42 tests.
- **PreferFinalClasses** (opt-in) — Adds `final` to classes not designed for subclassing. Pre-scans for subclass relationships, checks "Base" naming and doc comments, converts `open` members to `public`. 30 tests.
- **PrivateStateVariables** (opt-in) — Adds `private` to `@State`/`@StateObject` properties without access control. Skips `@Previewable`. 11 tests.
- **StrongOutlets** (default-on) — Removes `weak` from `@IBOutlet` properties. Preserves delegate/datasource outlets. 9 tests.

Moved 5 rules to c7r-77o (blocked) due to complexity: propertyTypes, trailingClosures, unusedArguments, unusedPrivateDeclarations, urlMacro.
