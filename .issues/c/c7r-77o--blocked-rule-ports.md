---
# c7r-77o
title: Blocked rule ports
status: in-progress
type: epic
priority: normal
created_at: 2026-04-14T04:25:28Z
updated_at: 2026-04-14T19:55:34Z
sync:
    github:
        issue_number: "293"
        synced_at: "2026-04-14T18:45:51Z"
---

Rules from porting efforts that are blocked or deferred, organized by implementation difficulty. Phases are tracked as child issues.

## Blocker Category Analysis

Investigation of the swift-syntax source at `~/Developer/apple/swift-syntax` and the existing rule patterns in Swiftiomatic reveals that the blocked rules cluster into distinct blocker categories, each requiring a different strategy.

| Category | Rules | Actual Difficulty |
|----------|-------|-------------------|
| A. Not actually blocked | 3 | Ready to implement |
| B. Attribute removal boilerplate | 3 | Needs `AttributeListSyntax+Convenience` |
| C. Modifier removal boilerplate | 5 | Pattern exists (RedundantInternal); boilerplate only |
| D. Inheritance clause modification | 2 | Needs `InheritanceClauseSyntax+Convenience` |
| E. Expression restructuring | 5 | Architecturally supported; needs patterns |
| F. Cross-statement/declaration merging | 4 | Pattern exists (UseEarlyExits); moderate |
| G. Condition/list splitting | 3 | Pattern exists (DoNotUseSemicolons); moderate |
| H. Scope analysis | 1 | Genuinely hard; needs design |
| I. Rule extension | 2 | Just feature work |

### Category A: Not Actually Blocked (3 rules)

**`redundantPattern`** — Original blocker: "swift-syntax does not produce `ValueBindingPatternSyntax` for inner case patterns." **Incorrect.** The `ValueBindingPatternSyntax` IS produced — nested inside `PatternExprSyntax` inside `LabeledExprSyntax`.

**`strongifiedSelf` / `redundantBackticks`** — Original blocker: "backtick token positioning." **Solvable.** swift-syntax stores backticks as part of the token text. `SyntaxRewriter.visit(_ token: TokenSyntax)` intercepts ALL tokens. `Identifier.name` strips backticks automatically.

### Category B: Attribute Removal (3 rules)

**Rules**: `redundantObjc`, `redundantViewBuilder`, plus future attribute-removal rules.
**Solution**: `AttributeListSyntax+Convenience` — `attribute(named:)`, `removing(named:)`, `remove(named:)` with trivia transfer. ✅ Implemented.

### Category C: Modifier Removal (5 rules)

**Rules**: `redundantExtensionACL`, `redundantPublic`, `redundantLet`, `redundantBreak`, `redundantAsync`, `redundantThrows`, `redundantTypedThrows`.
**Solution**: Generic helper with key-path dispatch per declaration type (RedundantInternal pattern). 10 visit overrides per rule, each a one-liner.

### Category D: Inheritance Clause Modification (2 rules)

**Rules**: `redundantSendable`, `redundantEquatable`.
**Solution**: `InheritanceClauseSyntax+Convenience` — `contains(named:)`, `inherited(named:)`, `removing(named:)` with comma/trivia cleanup. ✅ Implemented.

### Category E: Expression Restructuring (5 rules)

**Rules**: `preferCountWhere`, `hoistTry`, `hoistAwait`, `isEmpty`, `preferKeyPath`.
**Solution**: Each rule visits a specific expression type and returns `ExprSyntax`. No new abstractions needed — complexity is per-rule logic.

### Category F: Cross-Statement/Declaration Merging (4 rules)

**Rules**: `conditionalAssignment`, `redundantProperty`, `redundantClosure`, `environmentEntry`.
**Solution**: Visit `CodeBlockItemListSyntax` and iterate with lookahead (UseEarlyExits pattern). `environmentEntry` spans two top-level declarations — requires `SourceFileSyntax`-level visitation.

### Category G: Condition/List Splitting (3 rules)

**Rules**: `andOperator`, `simplifyGenericConstraints`, `genericExtensions`.
**Solution**: Visit the parent list (e.g., `ConditionElementListSyntax`), split elements, rebuild. DoNotUseSemicolons / OneVariableDeclarationPerLine pattern.

### Category H: Scope Analysis (1 rule)

**Rule**: `redundantSelf`.
**Recommendation**: Start with conservative subset (SE-0269 cases), leave full version for later with lightweight scope resolver.

### Category I: Rule Extension (2 rules)

**Rules**: `redundantFileprivate`, `redundantParens`.
**Solution**: Extend existing rule classes (FileScopedDeclarationPrivacy, NoParensAroundConditions). Just feature work.

## Abstractions Built

- [x] `AttributeListSyntax+Convenience` — `attribute(named:)`, `remove(named:)`, `removing(named:)` with trivia cleanup
- [x] `InheritanceClauseSyntax+Convenience` — `contains(named:)`, `inherited(named:)`, `removing(named:)` with comma/trivia cleanup
- [x] `CodeBlockSyntax` body wrapping helpers — `bodyNeedsWrapping`, `wrappingBody(baseIndent:)`
- [x] `Trivia` helpers — `indentation`, `trimmingTrailingWhitespace`


### Testing Rules Deferred from m0v-ruy

**`noForceUnwrapInTests`** (Category E — Expression Restructuring) — Replace `x!` with `try XCTUnwrap(x)`/`try #require(x)` in tests. Complex expression-level restructuring: parse expression ranges, handle scope containment, convert `!`→`?`, `as!`→`as?` with optional chaining, wrap in unwrap calls, detect LHS assignments / equality comparisons / XCTAssertEqual contexts. ~370 lines in SwiftFormat with heavy token-based logic.

**`preferSwiftTesting`** (Categories B+D+E+I — Multi-faceted) — Convert XCTest suites to Swift Testing. Massive transformation: replace `import XCTest` with `import Testing` + `import Foundation`, remove XCTestCase conformance, convert setUp→init / tearDown→deinit, add `@Test` to test methods, convert ~20 XCT* helpers to `#expect`/`#require`, rename test methods, detect unsupported functionality. ~618 lines in SwiftFormat.



### ~~Deferred from zbx-pz6: `wrapMultilineFunctionChains`~~

No longer deferred — analysis was incorrect. The rule operates on source-level line breaks (trivia), not computed layout. Being implemented as a SyntaxFormatRule in zbx-pz6.
