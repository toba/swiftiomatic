---
# ka6-zh3
title: Declaration, modifier, and cleanup rules
status: in-progress
type: feature
priority: normal
created_at: 2026-04-14T03:18:17Z
updated_at: 2026-04-14T06:05:44Z
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
- [ ] `preferExplicitFalse` — Prefer `== false` over `!` prefix negation
- [ ] `preferFinalClasses` — Prefer `final class` unless designed for subclassing
- [ ] `privateStateVariables` — Add `private` to `@State` properties without explicit access control
- [ ] `propertyTypes` — Configure inferred (`let x = Foo()`) vs explicit (`let x: Foo = .init()`) property types
- [ ] `strongOutlets` — Remove `weak` from `@IBOutlet` properties
- [ ] `trailingClosures` — Use trailing closure syntax where applicable *(extend existing `NoEmptyTrailingClosureParentheses`)*
- [ ] `unusedArguments` — Mark unused function arguments with `_`
- [ ] `unusedPrivateDeclarations` — Remove unused `private`/`fileprivate` declarations
- [ ] `urlMacro` — Replace force-unwrapped `URL(string:)` with `#URL(_:)` macro
