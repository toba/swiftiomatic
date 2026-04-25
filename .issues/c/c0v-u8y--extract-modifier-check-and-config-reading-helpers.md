---
# c0v-u8y
title: Extract modifier-check and config-reading helpers
status: completed
type: task
priority: normal
created_at: 2026-04-25T20:42:40Z
updated_at: 2026-04-25T21:42:55Z
parent: 0ra-lks
sync:
    github:
        issue_number: "418"
        synced_at: "2026-04-25T22:35:10Z"
---

Two patterns repeat across many rule files and warrant a small extension.

## Findings

- [x] `modifiers.contains(where: { $0.name.tokenKind == .keyword(.<keyword>) })` — added `func contains(_ keyword: Keyword) -> Bool` to `DeclModifierListSyntax+Convenience.swift`. Refactored 14 single-keyword call sites across 11 rule files plus collapsed two adjacent checks in `RequireSuperCall` to use the existing `contains(anyOf:)`.
- [x] `context.configuration[Self.self]` and `context.configuration[<RuleName>.self]` — added `var ruleConfig: Value { context.configuration[Self.self] }` to the `SyntaxRule` protocol extension. Refactored 16 self-config sites across 13 rule files. Cross-rule reads (`LineLength`, `IndentationSetting`, `ClosingBraceAsBlankLine`, `CommentAsBlankLine`) intentionally untouched — those reference *other* rules' config and `ruleConfig` does not apply.

## Verification
- [x] Build clean.
- [x] Targeted tests pass: 303/303 across all 21 affected rule suites.

## Summary of Changes

**New helpers**

- `Sources/SwiftiomaticKit/Extensions/ModifierListSyntax+Convenience.swift` — added `contains(_ keyword: Keyword) -> Bool` next to the existing `contains(anyOf:)`.
- `Sources/SwiftiomaticKit/Syntax/SyntaxRule.swift` — added `var ruleConfig: Value { context.configuration[Self.self] }` on the `SyntaxRule` protocol extension. `Self.self` resolves to the conforming concrete rule type at the dynamic-dispatch call site.

**Refactored call sites**

`modifiers.contains(.keyword)` (single-keyword form), 14 sites:
- `Rules/Access/PreferFinalClasses.swift` (`.final`, `.open`)
- `Rules/Testing/PreferSwiftTesting.swift` (`.override` ×4, `.static`)
- `Rules/Redundant/RedundantLet.swift` (`.async`)
- `Rules/Declarations/RequireSuperCall.swift` (`.override`, plus `[.static, .class]` via `contains(anyOf:)`)
- `Rules/Idioms/PreferStaticOverClassFunc.swift` (`.override`)
- `Rules/Closures/MutableCapture.swift` (`.lazy`)
- `Rules/Idioms/AvoidNoneName.swift` (`.class`, `.static`)
- `Rules/StrongOutlets.swift` (`.weak`)

`ruleConfig` (self-config form), 16 sites across 13 files:
- `Rules/Literals/URLMacro.swift` ×3
- `Rules/Literals/InvisibleCharacters.swift`
- `Rules/FileHeader.swift`
- `Rules/Capitalization/CapitalizeAcronyms.swift`
- `Rules/PatternLetPlacement.swift` ×3
- `Rules/Sort/SortImports.swift` ×4
- `Rules/Indentation/SwitchCaseIndentation.swift`
- `Rules/Access/FileScopedDeclarationPrivacy.swift`
- `Rules/Access/ExtensionAccessLevel.swift`
- `Rules/Wrap/NestedCallLayout.swift`
- `Rules/Wrap/WrapSwitchCaseBodies.swift`
- `Rules/Wrap/WrapSingleLineBodies.swift`
- `Rules/Idioms/NoAssignmentInExpressions.swift`
- `Rules/Declarations/RequireSuperCall.swift`

Compound checks (`InitCoderUnavailable`, `RequireSuperCall:28`, `UnusedSetterValue`, `PreferSynthesizedInitializer`'s `& $0.detail == nil` cases) left as-is — they have additional predicates beyond the keyword that make `contains(_:)` insufficient.
