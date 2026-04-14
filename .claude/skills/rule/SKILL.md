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

## Workflow: New Rule

1. Check `~/Developer/swiftiomatic-ref/SwiftFormat/Sources/Rules/` for a reference implementation
2. Create `Sources/Swiftiomatic/Rules/MyRule.swift` using the lint or format template below
3. Run `swift run generate-swiftiomatic` to register
4. Create `Tests/SwiftiomaticTests/Rules/MyRuleTests.swift` using the test template below
5. Adapt edge-case tests from `~/Developer/swiftiomatic-ref/SwiftFormat/Tests/Rules/`
6. Build and test

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
- For non-XCTest import detection (e.g., `import Testing`), use a private `var` flag set in `visit(_ node: ImportDeclSyntax)` — see format-rule-patterns.md § Import Detection

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

1. `API/Configuration.swift` — CodingKeys, property, decode, encode, struct
2. `API/Configuration+Default.swift` — default in `init()`
3. `Tests/SwiftiomaticTestSupport/Configuration+Testing.swift` — default in `forTesting`
4. Rule file — access via `context.configuration.myConfig`

## Diagnosing Rule Issues

| Problem | Check |
|---------|-------|
| Rule doesn't trigger | Correct `visit()` node type? `generate-swiftiomatic` run? `isOptIn` + `forTesting`? Missing `super.visit` in parent? |
| False positive | Write a test, add guard conditions (test files, bindings, closures) |
| Wrong output | `assertFormatting` test, check trivia, check `super.visit` |
| Finding at wrong position | Diagnosing on modified statement? Use `originalStatements[i].item` (see trivia-and-testing.md § Position Shift). Using `CodeBlockItemSyntax` instead of `.item`? Pipeline cross-rule interference — use `forTesting(enabledRule:)` (see trivia-and-testing.md § Pipeline cross-rule position shift). Diagnosing on `bindingSpecifier` instead of `varDecl`? Use the declaration node so the position accounts for modifiers (see trivia-and-testing.md § diagnose Target). |
| Double space after removing accessor block | Removing `accessorBlock` from a `PatternBindingSyntax` leaves trailing space on the type annotation. Use `typeAnnotation.type = typeAnnotation.type.trimmed` before adding initializer (see trivia-and-testing.md § Accessor Block Removal Trivia). |
| Blank line detection wrong | Counting newlines after comments? Only count before first non-whitespace (see trivia-and-testing.md § Blank Line Detection). |
| Per-arg pattern wildcards not detected | `case .bar(let _)` puts `let` as `LabeledExprSyntax.label` with `colon: nil`. Check `arg.expression.trimmedDescription == "_"` as fallback (see ast-and-extensions.md § Per-Argument Binding Label Quirk). |
| "Inside type" check too broad | `isInsideTypeDeclaration` via parent chain matches the type's OWN name. Use `MemberBlockSyntax` instead (see ast-and-extensions.md § isInsideTypeDeclaration Pitfall). |
| "After dot" misses type members | `MemberAccessExprSyntax` only covers expression dot access. Type dot access (`Foo.Type`) uses `MemberTypeSyntax` — check both (see ast-and-extensions.md § Member Access: Expression vs Type). |
| Extension `Foo.Bar` treated as `Foo` | `extendedType.trimmedDescription` matches as string. Guard with `extendedType.as(IdentifierTypeSyntax.self)` — `MemberTypeSyntax` is a different logical type (see ast-and-extensions.md § Extension Type Name). |
| Nested visitor not firing on early return | `guard ... else { return node }` skips descendants. Use `super.visit(node)` in fallback paths when the node can contain descendants other visitors handle (see trivia-and-testing.md § super.visit Rules). |
| String interpolation in test string | `\(x)` in triple-quoted test strings is Swift interpolation, not literal. Escape as `\\(x)` (see trivia-and-testing.md § String Interpolation in Test Strings). |
| Double newline after replacing nested code block item | Passing `leadingTrivia:` to `CodeBlockItemSyntax` init when the modified expression already carries original trivia. Omit `leadingTrivia:` for nested items that preserve their structure (see trivia-and-testing.md § Trivia Duplication When Replacing CodeBlockItemSyntax). |
| Pipeline trailing space after brace wrap | When moving `{` to its own line, the trailing whitespace on the preceding token remains. Strip it by modifying the parent node's property (e.g., `result.elseKeyword.trailingTrivia`) — see WrapMultilineStatementBraces pattern. |
| Multiline detection via indentation comparison | Don't scan for newlines in tokens between start and `{` — this catches newlines inside nested scopes (`[]`, `()`). Instead compare indentation: if the line indent of the token before `{` > closing `}` indent, the signature is multiline (SwiftFormat's `shouldWrapMultilineStatementBrace` approach). |
| Finding on comment trivia | `diagnose(on: token)` places finding at the token's content position, not its comment trivia. Use `diagnose(on: token, anchor: .leadingTrivia(triviaIndex))` to anchor at the comment piece in the token's leading trivia. |
| Modifying sibling tokens in SyntaxRewriter | Can't modify a sibling token from a child visitor. Use a `TokenStripper` helper rewriter (SyntaxRewriter that targets a specific `SyntaxIdentifier`) applied to the parent, or modify sibling properties on the parent node directly (e.g., `result.signature.trailingTrivia`). |
| Double space after where clause removal | Removing `genericWhereClause` keeps preceding token's trailing space AND body `{` gets forced space. Fix: strip trailing trivia from preceding token (return type or `)`) AND set `body.leftBrace.leadingTrivia = .space` (see format-rule-patterns.md § Generic Parameter and Where Clause Removal). |
| Finding at wrong position for attributed declarations | `diagnose(on: visited)` where `visited` is a `FunctionDeclSyntax` with attributes resolves to the attribute's position, not the keyword. Use `diagnose(on: node.funcKeyword)` / `node.initKeyword` / `node.subscriptKeyword` to target the keyword (see trivia-and-testing.md § diagnose Target). |
| Rule seems to need PrettyPrinter | Check if the rule operates on SOURCE trivia (existing newlines) vs COMPUTED layout (line length). Consistency rules ("if any X is wrapped, wrap all X") often work on source trivia and can be SyntaxFormatRules. Only rules that depend on column position after layout truly need PrettyPrinter changes. |
| Chain visitor fires on inner calls | When visiting `FunctionCallExprSyntax` for chains, inner calls in `a.b().c()` also match. Check `isInnerChainCall` — skip if parent is `MemberAccessExprSyntax` whose parent is another call/subscript. See format-rule-patterns.md § Walk and Wrap Function Call Chains. |

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

Load the specific reference matching your task:

| Need to... | Reference |
|---|---|
| Remove/add modifiers, attributes, inheritance, type specifiers | [format-declaration-patterns.md](references/format-declaration-patterns.md) |
| Replace expressions, restructure chains, hoist try/await | [format-expression-patterns.md](references/format-expression-patterns.md) |
| Split/merge lists, blank lines, file-level analysis, import detection | [format-list-and-file-patterns.md](references/format-list-and-file-patterns.md) |
| Wrap braces/comments, scan tokens, walk call chains | [format-wrapping-patterns.md](references/format-wrapping-patterns.md) |
| Trivia bugs, super.visit issues, test failures, marker placement | [trivia-and-testing.md](references/trivia-and-testing.md) |
| AST node types, convenience extensions, position APIs | [ast-and-extensions.md](references/ast-and-extensions.md) |
