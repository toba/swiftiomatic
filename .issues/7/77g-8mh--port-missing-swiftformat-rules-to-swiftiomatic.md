---
# 77g-8mh
title: Port missing SwiftFormat rules to Swiftiomatic
status: completed
type: epic
priority: normal
created_at: 2026-04-14T03:16:43Z
updated_at: 2026-04-14T19:04:24Z
sync:
    github:
        issue_number: "285"
        synced_at: "2026-04-15T00:34:43Z"
---

## Gap Analysis

Compared Swiftiomatic's 43 rules against nicklockwood/SwiftFormat's 142 rules (ref at `~/Developer/swiftiomatic-ref/SwiftFormat`).

- **Already covered**: 15 rules have Swiftiomatic equivalents
- **PrettyPrinter covers**: 22 rules are handled by `TokenStreamCreator`/`PrettyPrint` (indent, spacing, trailing whitespace, line wrapping, consecutive blanks, braces, else placement, trailing commas, wrap attributes)
- **Deprecated/duplicate**: 4 rules (specifiers, sortedSwitchCases, sortImports, redundantVariable)
- **Missing**: ~101 rules need implementation

## Architecture Differences

**SwiftFormat** uses a custom tokenizer producing a flat token stream. Rules operate on `Token` arrays with prev/next navigation — trivial for whitespace, harder for semantics.

**Swiftiomatic** uses **swift-syntax AST** with `SyntaxVisitor`/`SyntaxRewriter`. Semantic rules are more natural but whitespace lives in the **PrettyPrinter** (`TokenStreamCreator.swift`), not individual rules.

## Implementation Strategy

### Scope Assignment
- **`.lint`** — correctness, anti-patterns (editor warnings). Use `SyntaxLintRule`.
- **`.format`** — auto-fixable formatting. Use `SyntaxFormatRule`.
- **`.suggest`** — complex patterns needing human review (high false-positive).

### By Category

1. **Redundancy & Modern Idioms** (Categories 1–2): Pure AST. `SyntaxLintRule` with corrections. Visit syntax node → detect construct → emit diagnostic + fix-it. Translate SwiftFormat's token logic to swift-syntax node matching.

2. **Blank Lines & Wrapping** (Categories 3–4): PrettyPrinter enhancements or `SyntaxFormatRule`. Blank-line rules insert/remove `Token.newlines()` via `TokenStreamCreator`. Study existing blank-line handling first.

3. **Organization & Docs** (Category 5): `SyntaxFormatRule` for sorting/headers. `organizeDeclarations` is complex — start with `.suggest` scope.

4. **Testing** (Category 6): `SyntaxLintRule`. Detect test context via file naming, `@Test` attribute, or `XCTestCase` subclass.

5. **Declarations & Cleanup** (Category 7): Mixed. Modifier ordering needs canonical order config.

### Workflow per Rule

1. Create `Sources/Swiftiomatic/Rules/<RuleName>.swift`
2. Subclass `SyntaxLintRule` or `SyntaxFormatRule`
3. Add examples (good + bad) — validated by `RuleExampleTests`
4. Run `swift run GeneratePipeline`
5. Run full `RuleExampleTests` batch

### Priority Order

Start with **Redundancy** and **Modern Idioms** — pure AST with clear semantics. Spacing/wrapping require PrettyPrinter expertise and come later.
