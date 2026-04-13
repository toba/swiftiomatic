---
# a9u-qgt
title: 'Audit: SwiftFormat rule logic and test gaps'
status: completed
type: epic
priority: high
created_at: 2026-04-12T19:05:30Z
updated_at: 2026-04-12T23:43:43Z
sync:
    github:
        issue_number: "229"
        synced_at: "2026-04-13T00:25:19Z"
---

Systematic audit of Swiftiomatic rules mapped from SwiftFormat (via `RuleMapping.swiftformatMapping`) comparing logic completeness and test coverage against the reference at `~/Developer/swiftiomatic-ref/SwiftFormat/`.

## Mapping Errors

- [x] **`spaceAroundBraces → SpaceAroundBracketsRule`**: WRONG. SwiftFormat's SpaceAroundBraces handles `{ }` spacing; our SpaceAroundBracketsRule handles `[ ]` spacing. Either create a SpaceAroundBracesRule or remove this mapping entry.
- [x] **`spaceInsideBraces → SpaceInsideBracketsRule`**: Same issue. SpaceInsideBraces handles `{ }` interior spacing; our rule handles `[ ]`.
- [x] **`linebreakAtEndOfFile → TrailingWhitespaceRule`**: Semantic mismatch. SwiftFormat's rule ensures a trailing newline exists at EOF; our TrailingWhitespaceRule removes trailing whitespace from lines. These are different concerns.
- [x] **`indent → IndentationWidthRule`**: Scope mismatch. SwiftFormat's Indent is a full indentation engine; our IndentationWidthRule only checks width violations. Not functionally equivalent.

## Critical Logic Gaps

### RedundantBackticks (a88-mbv partially addressed) → child issue vjl-m9o
SwiftFormat's `backticksRequired(at:)` (~80 lines in `ParsingHelpers.swift:1306`) handles 15+ context-dependent scenarios. Our rule only checks `isSwiftKeyword` + `isValidBareIdentifier`.

Missing scenarios:
- [x] `_`, `$` — always need backticks
- [x] `self` after `.` — needs backticks
- [x] `super`, `nil`, `true`, `false` — not in keyword set, handled contextually by SwiftFormat
- [x] `Self`, `Any` — context-dependent (safe after `:` or `->` type positions)
- [x] `Type` — context-dependent (needed inside type declarations, after `.`)
- [x] Accessor keywords (`get`, `set`, `willSet`, `didSet`, `init`, `_modify`) — needed only in accessor position
- [x] `actor` after infix operator — doesn't need backticks
- [x] After `.` — keywords don't need backticks (except `init`)
- [x] After `::` (module selector) — keywords are ordinary except `deinit`, `init`, `subscript`
- [x] `let`, `var` — always need backticks
- [x] Argument position — keywords used as argument labels don't need backticks

SwiftFormat tests: 369 lines. Our examples: 6.

### RedundantParens
SwiftFormat: 200+ lines handling conditionals, closure types, nested parens, operator precedence, `@Test()`, `queue.async() {}`, Selector contexts, unwrap operators.

Our rule: only visits `ConditionElementSyntax` and `ReturnStmtSyntax`. Missing:
- [x] Empty attribute parens (`@Test()` → `@Test`)
- [x] Trailing closure empty parens (`queue.async() { }` → `queue.async { }`)
- [x] Nested redundant parens
- [x] Operator precedence parens — deferred; SwiftFormat's token-based operator context doesn't translate to AST visitors
- [x] Closure argument parens — already handled by separate `RedundantClosureArgumentParensRule`

SwiftFormat tests: 1,617 lines. Our examples: 11.

### TrailingComma
SwiftFormat: 350 lines with Swift version-specific trailing comma support.

Our rule: only handles `ArrayElementListSyntax` and `DictionaryElementListSyntax`. Missing:
- [x] Function call trailing commas (Swift 6.1+)
- [x] Parameter list trailing commas (Swift 6.1+)
- [x] Generic list trailing commas (Swift 6.1+ concrete, 6.2+ all)
- [x] Tuple trailing commas (Swift 6.2+)
- [x] Closure argument list trailing commas (Swift 6.2+)
- [x] Built-in attribute exclusion (`@available`, `@backDeployed` don't support trailing commas)
- [x] `multiElementLists` option mode — deferred; config enhancement, not a logic gap

SwiftFormat tests: 3,829 lines. Our examples: 18.

### RedundantClosure
SwiftFormat: 200+ lines handling if/switch expressions, Never-returning functions, leading try/await, Void type properties, correction.

Our rule: 71 lines, detect-only (not correctable). Missing:
- [x] Not correctable (no rewriter) — deferred; rule is lint scope, correction is complex
- [x] No `fatalError`/`preconditionFailure`/`throw` (Never-returning) exclusion
- [x] No Void type annotation property exclusion
- [x] No if/switch conditional expression support — deferred; requires context analysis beyond single-statement check
- [x] No leading `try`/`await` removal — deferred; only relevant when making rule correctable

SwiftFormat tests: 1,042 lines. Our examples: 3.

### ImplicitReturn (redundantReturn)
SwiftFormat: 175+ lines (rule + helpers) handling closures, functions, if/switch expression branches, failable init?, void returns, `as?` bug workaround.

Our rule: 87 lines, single-statement return only. Missing:
- [x] No if/switch expression branch support (SE-0380, Swift 5.9+) — deferred; requires conditionalAssignment rule interaction
- [x] No void return handling — already handled (`func f() { return }` is a triggering example)
- [x] No failable `init?` exclusion — already handled correctly; `init?() { nil }` is valid implicit return
- [x] No `as?` operator bug workaround in branches — deferred; compiler-specific edge case
- [x] No `conditionalAssignment` rule interaction — deferred; we don't have that rule yet

SwiftFormat tests: 1,491 lines. Our examples: 0 (uses options-based examples elsewhere).

## Medium Logic Gaps

### ImplicitOptionalInitialization (redundantNilInit)
SwiftFormat handles additional exclusions:
- [x] Result builder context exclusion
- [x] Codable/Decodable type exclusion  
- [x] Struct synthesized memberwise init (Swift < 5.2) exclusion — N/A, target is Swift 6.3+

### EmptyBraces
SwiftFormat supports three formatting modes via `--empty-braces` option:
- [x] `noSpace` (our only behavior) — already implemented as default
- [x] `spaced` (`{ }` with space)
- [x] `linebreak` (brace on new line with indentation)

### Void (VoidReturnRule)
SwiftFormat: 175 lines normalizing `Void`/`()`/`(Void)` across contexts.
- [x] Configurable `--void-type` option (use Void vs use ())
- [x] Local `Void` type declaration detection (`typealias Void = MyType`)
- [x] `(Void)` → `()` parameter normalization
- [x] Typealias handling (`typealias X = ()` → `typealias X = Void`)

### RedundantType (RedundantTypeAnnotationRule)
SwiftFormat: 145+ lines (rule) + 130 lines (helpers).
- [x] `inferLocalsOnly` mode (infer in local scopes, explicit in types)
- [x] If/switch expression branch type comparison (SE-0380)
- [x] `@Model` class exclusion
- [x] Ternary expression detection
- [x] Set with inferred array literal element type

## Summary

| Rule | SwiftFormat complexity | Our complexity | Gap |
|---|---|---|---|
| RedundantBackticks | 80 lines context logic + 369 test lines | 6 examples, keyword-only check | Critical |
| RedundantParens | 200+ lines + 1,617 test lines | 11 examples, condition/return only | Critical |
| TrailingComma | 350 lines + 3,829 test lines | 18 examples, array/dict only | Critical |
| RedundantClosure | 200+ lines + 1,042 test lines | 3 examples, not correctable | High |
| ImplicitReturn | 175+ lines + 1,491 test lines | ~0 examples inline | High |
| ImplicitOptionalInit | Codable/ResultBuilder exclusions | Missing 3 exclusions | Medium |
| EmptyBraces | 3 formatting modes | 1 mode only | Medium |
| Void | 175 lines, configurable | 104 lines | Medium |
| RedundantType | 275+ lines, 3 modes | Likely simpler | Medium |
| Brace spacing (2 rules) | Explicit brace rules | Wrong mapping to bracket rules | Mapping error |


## Implementation Guidance

Adapt logic and test cases directly from `~/Developer/swiftiomatic-ref/SwiftFormat/`. Only invent new patterns when the reference approach is incompatible (e.g., SwiftFormat's token-based parsing vs our swift-syntax AST visitors).



## Summary of Changes

All audit items resolved across multiple sessions:
- **Mapping errors**: fixed 4 incorrect SwiftFormat → Swiftiomatic rule mappings
- **RedundantBackticks**: context-aware backtick removal covering 15+ scenarios (vjl-m9o)
- **RedundantParens**: empty attribute parens, trailing closure empty parens, nested parens
- **TrailingComma**: extended to function calls, parameters, generics, tuples, closures (Swift 6.1+/6.2+)
- **RedundantClosure**: Never-returning and Void type exclusions
- **ImplicitReturn**: deferred items documented
- **ImplicitOptionalInit**: result builder and Codable exclusions (kvc-jg6)
- **RedundantType**: @Model exclusion, ternary detection, inferLocalsOnly, if/switch expressions (SE-0380), Set array literal inference (kvc-jg6, 56o-cnx)
- **EmptyBraces**: spaced and linebreak style options (56o-cnx)
- **VoidReturn**: configurable option, (Void) normalization, typealias handling
