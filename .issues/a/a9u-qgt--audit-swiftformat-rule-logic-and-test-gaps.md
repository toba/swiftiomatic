---
# a9u-qgt
title: 'Audit: SwiftFormat rule logic and test gaps'
status: in-progress
type: epic
priority: high
created_at: 2026-04-12T19:05:30Z
updated_at: 2026-04-12T21:32:00Z
sync:
    github:
        issue_number: "229"
        synced_at: "2026-04-12T21:32:12Z"
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
- [ ] `_`, `$` — always need backticks
- [ ] `self` after `.` — needs backticks
- [ ] `super`, `nil`, `true`, `false` — not in keyword set, handled contextually by SwiftFormat
- [ ] `Self`, `Any` — context-dependent (safe after `:` or `->` type positions)
- [ ] `Type` — context-dependent (needed inside type declarations, after `.`)
- [ ] Accessor keywords (`get`, `set`, `willSet`, `didSet`, `init`, `_modify`) — needed only in accessor position
- [ ] `actor` after infix operator — doesn't need backticks
- [ ] After `.` — keywords don't need backticks (except `init`)
- [ ] After `::` (module selector) — keywords are ordinary except `deinit`, `init`, `subscript`
- [ ] `let`, `var` — always need backticks
- [ ] Argument position — keywords used as argument labels don't need backticks

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
- [ ] Result builder context exclusion
- [ ] Codable/Decodable type exclusion  
- [ ] Struct synthesized memberwise init (Swift < 5.2) exclusion

### EmptyBraces
SwiftFormat supports three formatting modes via `--empty-braces` option:
- [ ] `noSpace` (our only behavior)
- [ ] `spaced` (`{ }` with space)
- [ ] `linebreak` (brace on new line with indentation)

### Void (VoidReturnRule)
SwiftFormat: 175 lines normalizing `Void`/`()`/`(Void)` across contexts.
- [ ] Configurable `--void-type` option (use Void vs use ())
- [ ] Local `Void` type declaration detection (`typealias Void = MyType`)
- [ ] `(Void)` → `()` parameter normalization
- [ ] Typealias handling (`typealias X = ()` → `typealias X = Void`)

### RedundantType (RedundantTypeAnnotationRule)
SwiftFormat: 145+ lines (rule) + 130 lines (helpers).
- [ ] `inferLocalsOnly` mode (infer in local scopes, explicit in types)
- [ ] If/switch expression branch type comparison (SE-0380)
- [ ] `@Model` class exclusion
- [ ] Ternary expression detection
- [ ] Set with inferred array literal element type

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
