---
name: rule
description: >
  Create, modify, and diagnose Swiftiomatic rules. Use when:
  (1) creating a new rule, (2) modifying an existing rule,
  (3) debugging why a rule doesn't trigger or triggers incorrectly,
  (4) understanding the rule architecture, (5) creating test-related rules
  (XCTest, Swift Testing). Triggers on mentions of "rule", "lint rule",
  "format rule", "LintSyntaxRule", "StaticFormatRule",
  "StructuralFormatRule", "diagnose", "finding", "TestSuiteDetection",
  rule file paths under Sources/SwiftiomaticKit/Rules/.
---

# Rule Development

Architecture descends from [apple/swift-format](https://github.com/swiftlang/swift-format). The rule base classes have diverged from upstream. Read this file, not the upstream shape.

**Check the reference clone before citing it.** The skill cites `~/Developer/swiftiomatic-ref/swift-format` (upstream) and `~/Developer/swiftiomatic-ref/SwiftFormat` (Lockwood). Neither is present on every machine. Run `ls ~/Developer/swiftiomatic-ref/` first. When a clone is missing, work from the sources in this repository and say that you did, rather than quoting an upstream file you did not read.

## Rule Types

Three base classes. Each is generic over its configuration value.

| Base Class | Inherits | Traversal | Use for |
|---|---|---|---|
| `LintSyntaxRule<V>` | `SyntaxVisitor` + `InstanceSyntaxRule` | interleaved in one `LintCoordinator` walk | read-only checks, anti-patterns, flag-only findings |
| `StaticFormatRule<V>` | `SyntaxRule` only, no rewriter | dispatched from `RewritePipeline` in one walk | node-local rewrites, which is most format rules |
| `StructuralFormatRule<V>` | `SyntaxRewriter` + `InstanceSyntaxRule` | its own ordered pass after stage one | rules needing a settled tree (`SortImports`, blank-line policy, `FileHeader`) |

**Default to `StaticFormatRule`.** It carries no per-file state, so `Context` threads through each static call. Reach for `StructuralFormatRule` only when the rule needs instance traversal over a tree that stage one already settled.

Every rule declares `override class var group: ConfigurationGroup?` and ends its file with a `fileprivate extension Finding.Message`.

## Configuration Values

The generic parameter is the rule's config value. Pick one:

| Value | Encodes | Use for |
|---|---|---|
| `LintOnlyValue` | `lint` | a rule that can never rewrite. `rewrite` is hard-wired to `false` |
| `BasicRuleValue` | `lint`, `rewrite` | a format rule with no extra options |
| a custom `SyntaxRuleValue` struct | whatever you declare | a rule with its own knobs |

Defaults: `LintOnlyValue` starts at `.warn`. `BasicRuleValue` starts at `rewrite: true, lint: .warn`. Override with `override class var defaultValue:`.

```swift
// ship the rule off by default
override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

// lint by default, never rewrite by default
override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .warn) }
```

A custom value struct lives **in the rule's own file** and is `package`. There is no separate registration list to edit. See `Rules/Metrics/NestingDepth.swift` for the pattern: properties, `init()`, `init(from:)` decoding each key with `decodeIfPresent`, and a `CodingKeys` enum. Read it via `ruleConfig` on an instance rule, or `context.configuration[Self.self]` from a static one.

## File Layout

| What | Where |
|---|---|
| rule source | `Sources/SwiftiomaticKit/Rules/<Group>/MyRule.swift`, one per file |
| tests | `Tests/SwiftiomaticTests/Rules/MyRuleTests.swift` |
| generated files | `Sources/SwiftiomaticKit/Generated/`, never edited by hand |
| base classes | `Sources/SwiftiomaticKit/Syntax/` |

The `<Group>` directory matches the `ConfigurationGroup` the rule declares. Rule sources indent with **4 spaces**. Test files indent with **2 spaces**.

Groups: `access` `blankLines` `closures` `collections` `comments` `conditions` `controlFlow` `declarations` `generics` `hoist` `idioms` `indentation` `lineBreaks` `literals` `memory` `metrics` `naming` `redundancies` `sort` `spaces` `swiftui` `testing` `types` `unsafety` `wrap`.

## Workflow: New Rule

1. Check `~/Developer/swiftiomatic-ref/swift-format/Sources/SwiftFormat/Rules/` for a reference implementation, if that clone exists. Otherwise find the nearest existing rule in this repository and copy its shape.
2. Write a failing test first at `Tests/SwiftiomaticTests/Rules/MyRuleTests.swift`
3. Create the rule under the group directory that matches its `ConfigurationGroup`
4. For a `StaticFormatRule`, add its dispatch line to `RewritePipeline` (see Registration)
5. Adapt edge-case tests from `~/Developer/swiftiomatic-ref/swift-format/Tests/SwiftFormatTests/Rules/`
6. Build, run the suite filtered to the new test class, then format the new files with `sm`

## Creating a Lint Rule

```swift
import SwiftSyntax

/// Brief description.
///
/// Longer paragraph on why the old form is worse than the new one.
///
/// Lint: The condition that raises a warning.
final class MyNewRule: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    override func visit(_ node: SomeNodeSyntax) -> SyntaxVisitorContinueKind {
        guard violationCondition else { return .visitChildren }
        diagnose(.myMessage, on: node)
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let myMessage: Finding.Message = "description"
}
```

- Return `.visitChildren` or `.skipChildren`
- `@unchecked Sendable` is required on the class, because the base class declares it
- `context.importsXCTest` / `node.hasTestAncestor` to skip test code
- For test-related rules, use `TestSuiteDetection.swift` helpers — see Test-Related Rules below
- For non-XCTest import detection (e.g., `import Testing`), use a private `var` flag set in `visit(_ node: ImportDeclSyntax)` — see format-list-and-file-patterns.md § Import Detection

## Creating a Static Format Rule

The default choice for a format rule. No `visit` override and no `super.visit` call. `RewritePipeline` already recursed the children before it calls `transform`.

```swift
import SwiftSyntax

/// Brief description.
///
/// Lint: The condition that raises a warning.
///
/// Rewrite: What the rewrite does.
final class MyFormatRule: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }

    static func transform(
        _ node: SomeNodeSyntax,
        original _: SomeNodeSyntax,
        parent _: Syntax?,
        context: Context
    ) -> SomeNodeSyntax {
        guard shouldModify(node) else { return node }
        Self.diagnose(.myMessage, on: node.someToken, context: context)
        return node.with(\.child, replacement)
    }
}

fileprivate extension Finding.Message {
    static var myMessage: Finding.Message { "description" }
}
```

- `original` is the node **before** any earlier rule in the chain touched it. Use it when the rewrite needs the source shape, and `_`-name it otherwise.
- `parent` is the parent of the original node. `RewritePipeline` captures it before recursing.
- Return the same node kind, or a wider supertype of the same family. `RewritePipeline` drops a result that widens to a different kind.
- Add `static func willEnter(_ node:context:)` and `static func didExit(_ node:context:)` when the rule needs a scope stack. Store the stack on `Context`, not on the rule. See `Rules/Hoist/HoistTry.swift`.

## Creating a Structural Format Rule

```swift
final class MyStructuralRule: StructuralFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .sort }

    override func visit(_ node: SomeNodeSyntax) -> ReturnType {
        let visited = super.visit(node)  // recurse children first
        guard let typed = visited.as(SomeNodeSyntax.self) else { return visited }
        guard shouldModify(typed) else { return visited }
        diagnose(.myMessage, on: typed)
        return ReturnType(modified)
    }
}
```

**Return types are covariant** (parent protocol, not concrete type):
- `FunctionDeclSyntax` → `DeclSyntax` | `InfixOperatorExprSyntax` → `ExprSyntax` | `CodeBlockItemListSyntax` → `CodeBlockItemListSyntax`
- Can return a different concrete type within the same family (e.g., `StructDeclSyntax` → `EnumDeclSyntax`)

**`super.visit(node)` rule**: Call it when the rule visits descendant node types. Containers (class/struct/enum/actor/protocol/extension) always need it. Skip only for leaf nodes with no child visitors. See [references/trivia-and-testing.md](references/trivia-and-testing.md).

Per-pass gating lives at the `RewriteCoordinator` call site, so a new structural pass needs a line there.

## Diagnosis API

Two spellings. An instance rule uses the instance form. A `StaticFormatRule` uses the static form, which takes the `Context` explicitly.

```swift
// LintSyntaxRule, StructuralFormatRule
diagnose(_ message: Finding.Message, on node: SyntaxType?, anchor: FindingAnchor = .start, notes: [Finding.Note] = [])

// StaticFormatRule
Self.diagnose(_ message: Finding.Message, on node: SyntaxType?, context: Context, anchor: FindingAnchor = .start, notes: [Finding.Note] = [])
```

Anchors: `.start` (default), `.leadingTrivia(index)`, `.trailingTrivia(index)`.

An instance rule also has a severity-override form, `diagnose(_:on:severity:anchor:notes:)`, used by metrics rules that warn over one threshold and error over another.

## Registration

The `GenerateCode` SPM build tool plugin runs the `Generator` executable **on every build**. It scans the rule sources, detects the base class, and writes the generated files. A new rule needs no manual registration step to appear in the pipeline, the configuration registry, or the schema.

Two things are still hand-written.

1. **A `StaticFormatRule` needs a dispatch line in `RewritePipeline`.** Find the `visit(_ node:)` override for the node type the rule transforms, and add:

   ```swift
   apply(MyFormatRule.self, to: &current, original: node, gate: gate) {
       MyFormatRule.transform($0, original: $1, parent: parent, context: $2)
   }
   ```

   Use `applyWidening` when the transform may return a different node kind, and `applyAsserting` when the chain has already widened to a supertype. If the node type has no `visit` override yet, add one, following a neighbouring override.

2. **`schema.json` at the package root is not part of the build.** Refresh it with `swift run Generator` after adding, removing, or renaming a rule.

Never edit `*+Generated.swift`.

## Testing

```swift
@testable import Swiftiomatic
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

**Imports**: `@testable import SwiftiomaticKit`, `import SwiftiomaticTestSupport`, `import Testing`. The `RuleTesting` protocol lives in `Tests/SwiftiomaticTests/Rules/LintOrFormatRuleTestCase.swift`.

**`assertFormatting`** asserts the formatted output first, then the findings. Both must match. It accepts any `SyntaxRule`, so a `StaticFormatRule` needs no rewriter to be testable.

Both helpers force the rule on with `Configuration.forTesting(enabledRule:)`, so a rule that ships off by default still runs under test. Pass an explicit `configuration:` to test a non-default value.

**Message text is compared verbatim.** Hoist each expected message into a `private static let` on the suite so the rule file and the test cannot drift apart silently.

**Adapt the swift-format reference tests** from `~/Developer/swiftiomatic-ref/swift-format/Tests/SwiftFormatTests/Rules/` when that clone exists. They catch real bugs. Without it, cover the same ground by hand: one test per positive shape, one per near-miss that must not fire, and one for the already-correct form.

## Test-Related Rules

`Syntax/TestSuiteDetection.swift` provides shared helpers for rules that operate on test code:

```swift
// Detect which testing framework the file uses (returns nil if both or neither)
let framework = detectTestFramework(in: sourceFileSyntax)  // .xcTest | .swiftTesting | nil

// Check if a type declaration is a test suite (skips open/Base types)
isTestSuite(name:, inheritanceClause:, modifiers:, leadingTrivia:, framework:)

// Check for parameterized test inits (skip these types)
hasParameterizedInit(memberBlock)

// Disabled test detection
hasDisabledPrefix(functionName)  // checks "disable_", "skip_", "x_", "_" etc.
```

Use `detectTestFramework` instead of `context.importsXCTest` when the rule needs to handle both XCTest and Swift Testing, or when it needs to distinguish between them. `context.importsXCTest` is still fine for rules that only care about XCTest.

Used by: `ValidateTestCases`, `TestSuiteAccessControl`, `NoForceTry`, `NoForceUnwrap`, `PreferSwiftTesting`.

## Rule Configuration

There is no multi-file checklist. The rule's config value **is** its configuration, and the generator picks it up from the rule file.

- No extra options: use `LintOnlyValue` or `BasicRuleValue` and stop.
- Extra options: declare a `package struct MyRuleConfiguration: SyntaxRuleValue` in the rule's own file, then subclass on it. See `Rules/Metrics/NestingDepth.swift`.

Read it with `ruleConfig` on an instance rule, or `context.configuration[Self.self]` from a static one. Run `swift run Generator` afterwards so `schema.json` picks up the new keys.

## Diagnosing Rule Issues

| Problem | Check |
|---------|-------|
| Rule doesn't trigger | Correct `visit()` node type? For a `StaticFormatRule`, is the dispatch line present in `RewritePipeline` for that node type? Missing `super.visit` in parent? |
| Format rule builds but never rewrites | A `StaticFormatRule` with no `RewritePipeline` dispatch line compiles, registers, and is never called. This is the most common cause. |
| `transform` result silently dropped | `apply` keeps the result only when it still casts to the original node kind. Use `applyWidening` when the kind changes. |
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
| Double space after where clause removal | Removing `genericWhereClause` keeps preceding token's trailing space AND body `{` gets forced space. Fix: strip trailing trivia from preceding token (return type or `)`) AND set `body.leftBrace.leadingTrivia = .space` (see format-declaration-patterns.md § Generic Parameter and Where Clause Removal). |
| Finding at wrong position for attributed declarations | `diagnose(on: visited)` where `visited` is a `FunctionDeclSyntax` with attributes resolves to the attribute's position, not the keyword. Use `diagnose(on: node.funcKeyword)` / `node.initKeyword` / `node.subscriptKeyword` to target the keyword (see trivia-and-testing.md § diagnose Target). |
| Wrapping at wrong level in expression chain | Rule wraps at inner ForceUnwrapExpr giving `try XCTUnwrap(foo).bar` instead of `try XCTUnwrap(foo?.bar)`. Use chain-top wrapping pattern: convert inner nodes, wrap at chain top via flag (see format-expression-patterns.md § Chain-Top Wrapping). |
| `=` operator check fails | After `operatorTable.foldAll`, `=` uses `AssignmentExprSyntax` not `BinaryOperatorExprSyntax`. Check `op.is(AssignmentExprSyntax.self)` (see format-expression-patterns.md § Assignment operator). |
| `chainNeedsWrapping` flag leaks between siblings | Chain top visitors must save/restore flag: `let saved = chainNeedsWrapping; chainNeedsWrapping = false; let visited = super.visit(node); let childFlag = chainNeedsWrapping; chainNeedsWrapping = saved \|\| childFlag`. |
| Chain top detected too early | `isChainTop` missing `ForceUnwrapExprSyntax` or `OptionalChainingExprSyntax` as chain continuation nodes — intermediate MemberAccessExpr nodes falsely think they're the top. Include ALL chain node types. |
| Replacement expression loses indentation | Newly constructed syntax nodes have empty trivia. Transfer `leadingTrivia`/`trailingTrivia` from original node to replacement (see format-expression-patterns.md § Trivia Transfer). |
| Missing space after removing inheritance clause | `removing(named:)` returns `nil` for empty list (success), not "not found". When setting `inheritanceClause = nil`, add `result.memberBlock.leftBrace.leadingTrivia = .space` (see format-expression-patterns.md § Removing Inheritance Clause). |
| Modifier removal loses leading trivia | Removing `override` from modifiers loses the blank line + indentation that was on `override`. Use `node.leadingTrivia` (original) for the replacement init/deinit keyword, not `result.leadingTrivia` (see format-expression-patterns.md § Replacing Declaration Types). |
| Missing space before `{` after building init | Building a new `FunctionParameterClauseSyntax` loses trivia on `)`. Reuse `result.signature` from the original instead. For deinit (no parens), set `deinitKeyword.trailingTrivia` to the space before `{`. |
| `try await` call not detected for removal | `extractFunctionCall` only checks `TryExprSyntax.expression.as(FunctionCallExprSyntax.self)` — misses `AwaitExprSyntax` in between. Use recursive unwrapping through try/await layers (see format-expression-patterns.md § Unwrapping try/await Layers). |
| Rule seems to need PrettyPrinter | Check if the rule operates on SOURCE trivia (existing newlines) vs COMPUTED layout (line length). Consistency rules ("if any X is wrapped, wrap all X") often work on source trivia and can be format rules. Only rules that depend on column position after layout truly need PrettyPrinter changes. |
| Chain visitor fires on inner calls | When visiting `FunctionCallExprSyntax` for chains, inner calls in `a.b().c()` also match. Check `isInnerChainCall` — skip if parent is `MemberAccessExprSyntax` whose parent is another call/subscript. See format-wrapping-patterns.md § Walk and Wrap Function Call Chains. |
| Covariant return from `visit` doesn't propagate | Returning a different concrete type from a covariant `visit` (e.g., `WildcardPatternSyntax` from `visit(_ node: ValueBindingPatternSyntax) -> PatternSyntax`) is silently ignored by `SyntaxRewriter`. The visitor IS called, but `rewrite()` doesn't apply the change. **Fix**: modify at the PARENT level instead — visit the parent node and set its child property to the new value. |
| `is()` / `as()` type check fails after child-first traversal | After `SyntaxRewriter` visits children (child-first), reconstructed nodes may fail `is(ConcreteType.self)` checks even though `syntaxNodeType` shows the correct type. **Fix**: use `trimmedDescription == "_"` or similar string checks as a fallback when `is()` is unreliable. |
| Leading delimiter trivia rearrangement | Moving a `,` or `:` from start of line to end of previous line requires modifying BOTH the delimiter token AND adjacent tokens. Use `visit(_ token: TokenSyntax)` with stored state (`pendingLeadingTrivia`, `pendingComment`) to coordinate trivia transfer across sibling tokens visited in source order. |
| Nested function treated as non-static | `isInStaticContext` stops at nested `func bar()` inside `static func foo()`. Nested functions are NOT direct type members. Check `funcDecl.parent?.is(MemberBlockItemSyntax.self)` — if false, continue walking up (see format-declaration-patterns.md § Static Context Detection). |
| Comment lost when removing type annotation | `typeAnnotation = nil` drops block comments in the type's trailing trivia (`var x: T /* c */ = val`). Transfer `typeAnnotation.type.trailingTrivia` to `initializer.equal.leadingTrivia` when it contains comments (see format-declaration-patterns.md § Remove Type Annotation with Comment Preservation). |
| Void check too narrow | `typeName == "Void"` misses `[Void]`, `Optional<Void>`, `Array<Void>`. Use `typeName.contains("Void")` to catch all Void-containing types. |
| Import insertion steals blank line | Inserting a new import after existing imports using `statements[next].leadingTrivia` for the import's trivia steals the blank-line separator. After existing imports use `.newline`; only at top (no imports) take the next statement's trivia and set `.newlines(2)` on it (see format-list-and-file-patterns.md § Import Insertion). |
| `/***...***/` not detected as block comment | swift-syntax classifies `/***...***/` (3+ asterisks) as `.docBlockComment`, not `.blockComment`. Include `.docBlockComment` in header/comment detection when decorative block borders should be matched. `.docLineComment` (`///`) remains distinct. |
| EOF-only file trivia mismatch | For files with no statements (comment-only), trivia is on `endOfFileToken`. Don't add `.newlines(1)` unconditionally — use `rest` (original trailing trivia) to avoid changing `[.lineComment("...")]` to `[.lineComment("..."), .newlines(1)]`. |

## Key Reference Files

Paths are relative to `Sources/SwiftiomaticKit/` unless noted.

| File | Purpose |
|------|---------|
| `Syntax/SyntaxRule.swift` | `SyntaxRule` / `InstanceSyntaxRule` protocols, both `diagnose()` spellings |
| `Syntax/StaticFormatRule.swift` | static format base, the default choice |
| `Syntax/Linter/LintSyntaxRule.swift` | lint base (`SyntaxVisitor`) |
| `Syntax/Rewriter/StructuralFormatRule.swift` | structural format base (`SyntaxRewriter`) |
| `Syntax/Rewriter/RewritePipeline.swift` | hand-written stage-one dispatch. A new `StaticFormatRule` is added here |
| `Syntax/Rewriter/RewriteCoordinator.swift` | stage-two ordering for structural passes |
| `Syntax/TestSuiteDetection.swift` | shared test framework and suite detection |
| `Extensions/SyntaxProtocol+Convenience.swift` | trivia and token helpers, `firstAndOnly` |
| `Extensions/InheritanceClauseSyntax+Convenience.swift` | `contains(named:)`, `inherited(named:)`, `removing(named:)` |
| `Extensions/AttributeListSyntax+Convenience.swift` | `attribute(named:)`, `removing(named:)` |
| `../ConfigurationKit/ConfigurationGroup.swift` | the group list |
| `../ConfigurationKit/LintOnlyValue.swift`, `BasicRuleValue.swift` | the two stock config values |
| `../../Tests/SwiftiomaticTests/Rules/LintOrFormatRuleTestCase.swift` | `RuleTesting`, `assertLint`, `assertFormatting` |

## References

Load the specific reference matching your task:

| Need to... | Reference |
|---|---|
| Remove/add modifiers, attributes, inheritance, type specifiers | [format-declaration-patterns.md](references/format-declaration-patterns.md) |
| Replace expressions, restructure chains, hoist try/await, chain-top wrapping, operator types, trivia transfer, inheritance removal, declaration type replacement, try/await unwrapping, bail-out, scope tracking | [format-expression-patterns.md](references/format-expression-patterns.md) |
| Split/merge lists, blank lines, file-level analysis, import detection | [format-list-and-file-patterns.md](references/format-list-and-file-patterns.md) |
| Wrap braces/comments, scan tokens, walk call chains | [format-wrapping-patterns.md](references/format-wrapping-patterns.md) |
| Trivia bugs, super.visit issues, test failures, marker placement | [trivia-and-testing.md](references/trivia-and-testing.md) |
| AST node types, convenience extensions, position APIs | [ast-and-extensions.md](references/ast-and-extensions.md) |
