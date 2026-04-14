---
# ka6-zh3
title: Declaration, modifier, and cleanup rules
status: ready
type: feature
priority: normal
created_at: 2026-04-14T03:18:17Z
updated_at: 2026-04-14T03:18:17Z
parent: 77g-8mh
sync:
    github:
        issue_number: "287"
        synced_at: "2026-04-14T03:28:23Z"
---

Port remaining declaration, modifier, access-control, and cleanup rules from SwiftFormat.

**Implementation**: Mixed `SyntaxLintRule` and `SyntaxFormatRule`. Modifier ordering needs a canonical order configuration option. Unused-code detection may need cross-file analysis (two-pass). Some extend existing Swiftiomatic rules.

## Rules

- [ ] `emptyBraces` — Remove whitespace inside empty braces (e.g. `{ }` → `{}`)
- [ ] `emptyExtensions` — Remove empty, non-protocol-conforming extensions
- [ ] `extensionAccessControl` — Configure extension ACL placement *(extend existing `NoAccessLevelOnExtensionDeclaration`)*
- [ ] `fileMacro` — Prefer `#file` or `#fileID` consistently (same behavior in Swift 6+)
- [ ] `hoistPatternLet` — Reposition `let`/`var` in patterns *(extend existing `UseLetInEveryBoundCaseVariable` + `NoLabelsInCasePatterns`)*
- [ ] `initCoderUnavailable` — Add `@available(*, unavailable)` to required `init(coder:)` without implementation
- [ ] `modifierOrder` — Enforce consistent ordering for declaration modifiers (e.g. `public static func` not `static public func`)
- [ ] `modifiersOnSameLine` — Ensure all modifiers are on the same line as the declaration keyword
- [ ] `noExplicitOwnership` — Remove explicit `borrowing`/`consuming` modifiers
- [ ] `preferExplicitFalse` — Prefer `== false` over `!` prefix negation
- [ ] `preferFinalClasses` — Prefer `final class` unless designed for subclassing
- [ ] `privateStateVariables` — Add `private` to `@State` properties without explicit access control
- [ ] `propertyTypes` — Configure inferred (`let x = Foo()`) vs explicit (`let x: Foo = .init()`) property types
- [ ] `strongOutlets` — Remove `weak` from `@IBOutlet` properties
- [ ] `trailingClosures` — Use trailing closure syntax where applicable *(extend existing `NoEmptyTrailingClosureParentheses`)*
- [ ] `unusedArguments` — Mark unused function arguments with `_`
- [ ] `unusedPrivateDeclarations` — Remove unused `private`/`fileprivate` declarations
- [ ] `urlMacro` — Replace force-unwrapped `URL(string:)` with `#URL(_:)` macro
