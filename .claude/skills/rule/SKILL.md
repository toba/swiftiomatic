---
name: rule
description: >
  Create, modify, and diagnose Swiftiomatic rules. Use when:
  (1) creating a new rule, (2) modifying an existing rule,
  (3) debugging why a rule doesn't trigger or triggers incorrectly,
  (4) understanding the rule architecture. Triggers on mentions of "rule",
  "lint rule", "format rule", "SyntaxLintRule", "SyntaxFormatRule",
  "diagnose", "finding", rule file paths under Sources/Swiftiomatic/Rules/.
---

# Rule Development

Architecture follows [apple/swift-format](https://github.com/swiftlang/swift-format). Reference clone at `~/Developer/swiftiomatic-ref/swift-format`.

## Rule Types

| Base Class | Inherits | Modifies Tree | Use Case |
|---|---|---|---|
| `SyntaxLintRule` | `SyntaxVisitor` + `Rule` | No | Read-only checks, anti-patterns, style |
| `SyntaxFormatRule` | `SyntaxRewriter` + `Rule` | Yes | Auto-fixable transformations |

Both emit findings via `diagnose()`. Format rules also lint (emit findings while transforming).

## File Layout

Rules: `Sources/Swiftiomatic/Rules/` (one per file). Tests: `Tests/SwiftiomaticTests/Rules/`.

## Creating a Lint Rule

```swift
import SwiftSyntax

/// Brief description.
///
/// Lint: When a lint warning is raised.
@_spi(Rules)
public final class MyNewRule: SyntaxLintRule {

  // public override class var isOptIn: Bool { true }

  public override func visit(_ node: SomeNodeSyntax) -> SyntaxVisitorContinueKind {
    guard violationCondition else { return .visitChildren }
    diagnose(.myMessage, on: node)
    return .visitChildren
  }
}

extension Finding.Message {
  fileprivate static let myMessage: Finding.Message = "description"
}
```

- Return `.visitChildren` or `.skipChildren`
- `context.importsXCTest` / `node.hasTestAncestor` to skip test code

## Creating a Format Rule

```swift
import SwiftSyntax

/// Brief description.
///
/// Lint: When a violation is found.
///
/// Format: The violation is corrected.
@_spi(Rules)
public final class MyFormatRule: SyntaxFormatRule {

  public override func visit(_ node: SomeNodeSyntax) -> ReturnType {
    let visited = super.visit(node)  // recurse children first
    guard let typedNode = visited.as(SomeNodeSyntax.self) else { return visited }
    guard shouldModify(typedNode) else { return visited }
    diagnose(.myMessage, on: typedNode)
    return ReturnType(modifiedNode)
  }
}
```

**Return types are covariant** (parent protocol, not concrete type):
- `FunctionDeclSyntax` → `DeclSyntax` | `InfixOperatorExprSyntax` → `ExprSyntax` | `CodeBlockItemListSyntax` → `CodeBlockItemListSyntax`
- Can return a different concrete type within the same family (e.g., `StructDeclSyntax` → `EnumDeclSyntax`)

**`super.visit(node)` rule**: Call it when the rule visits descendant node types. Containers (class/struct/enum/actor/protocol/extension) always need it. Skip only for leaf nodes with no child visitors. See [references/trivia-and-testing.md](references/trivia-and-testing.md).

## Diagnosis API

```swift
diagnose(_ message: Finding.Message, on node: SyntaxType?, anchor: FindingAnchor = .start, notes: [Finding.Note] = [])
```

Anchors: `.start` (default), `.leadingTrivia(index)`, `.trailingTrivia(index)`.

## Registration

After creating/renaming/removing rules: `swift run generate-swiftiomatic`. Never edit `*+Generated.swift`.

## Testing

```swift
@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct MyRuleTests: RuleTesting {
  @Test func lintTest() {
    assertLint(MyLintRule.self, """
      let x = 1️⃣expr!
      """, findings: [FindingSpec("1️⃣", message: "msg")])
  }

  @Test func formatTest() {
    assertFormatting(MyFormatRule.self,
      input: """
        before 1️⃣code
        """,
      expected: """
        after code
        """,
      findings: [FindingSpec("1️⃣", message: "msg")])
  }
}
```

**Markers** (`1️⃣`): Place at the first non-trivia token of the node passed to `diagnose()`.

**`assertFormatting`** runs two passes (single rule + full pipeline). Both must match.

**Always adapt SwiftFormat reference tests** from `~/Developer/swiftiomatic-ref/SwiftFormat/Tests/Rules/` — they catch real bugs.

## Rule Configuration (4-file checklist)

1. `Configuration.swift` — CodingKeys, property, decode, encode, struct
2. `Configuration+Default.swift` — default in `init()`
3. `Configuration+Testing.swift` — default in `forTesting`
4. Rule file — access via `context.configuration.myConfig`

## Diagnosing Rule Issues

| Problem | Check |
|---------|-------|
| Rule doesn't trigger | Correct `visit()` node type? `generate-swiftiomatic` run? `isOptIn` + `forTesting`? Missing `super.visit` in parent? |
| False positive | Write a test, add guard conditions (test files, bindings, closures) |
| Wrong output | `assertFormatting` test, check trivia, check `super.visit` |
| Finding at wrong position | Diagnosing on modified statement? Use `originalStatements[i].item` (see trivia-and-testing.md § Position Shift). Using `CodeBlockItemSyntax` instead of `.item`? |
| Blank line detection wrong | Counting newlines after comments? Only count before first non-whitespace (see trivia-and-testing.md § Blank Line Detection). |

## Key Reference Files

| File | Purpose |
|------|---------|
| `Core/Rule.swift` | `Rule` protocol, `diagnose()` |
| `Core/SyntaxLintRule.swift` | Lint base (`SyntaxVisitor`) |
| `Core/SyntaxFormatRule.swift` | Format base (`SyntaxRewriter`) |
| `Core/Context.swift` | Config, findings, rule mask |
| `Core/SyntaxProtocol+Convenience.swift` | Trivia/token helpers |
| `Tests/.../LintOrFormatRuleTestCase.swift` | `RuleTesting` protocol |

## References

Load these when you need detailed patterns or hit issues:

| Reference | When to load |
|-----------|-------------|
| [references/format-rule-patterns.md](references/format-rule-patterns.md) | Creating/modifying any format rule. Covers 13 patterns: change node types, token visitors, remove declarations, stateful rewriting, brace collapsing, split lists (1→N), merge statements (N→1), remove modifiers, remove type specifiers, replace expressions, multi-property modification, restructure method chains, hoist try/await. |
| [references/trivia-and-testing.md](references/trivia-and-testing.md) | Trivia bugs, wrong whitespace, `super.visit` issues, test failures. Covers trivia ownership, boundary transfer, where clause trivia, marker placement, `assertFormatting` mechanics, SwiftFormat reference test adaptation, known limitations. |
| [references/ast-and-extensions.md](references/ast-and-extensions.md) | Understanding AST structure, finding the right node type, using convenience extensions. Covers `ConditionElementSyntax` kinds, enum case patterns, `SyntaxRewriter` hooks, `SyntaxChildChoices` API notes, convenience extensions on modifiers/trivia/syntax, swift-syntax source locations. |
| [references/swift-syntax-api.md](references/swift-syntax-api.md) | Position/location APIs, trivia manipulation, token navigation, file access, common patterns. |
