---
name: rule
description: >
  Create, modify, and diagnose Swiftiomatic lint/format/suggest rules. Use when:
  (1) creating a new rule, (2) adding examples or corrections to an existing rule,
  (3) making a rule correctable, (4) adding custom options/configuration,
  (5) debugging why a rule doesn't trigger or triggers incorrectly,
  (6) understanding the rule architecture. Triggers on mentions of "rule",
  "lint rule", "format rule", "suggest rule", "SwiftSyntaxRule", "SourceKitASTRule",
  "correctable", "visitor", "rewriter", rule file paths under Sources/SwiftiomaticKit/Rules/.
---

# Rule Creation

## Rule Types

| Protocol | Input | Pipeline Eligible | Use Case |
|----------|-------|-------------------|----------|
| `SwiftSyntaxRule` | SwiftSyntax AST | Yes | Syntactic checks, formatting, most rules |
| `SwiftSyntaxRule` (visitor doesn't reference `violations`) | SwiftSyntax AST | No (auto-detected fallback) | Rules whose `validate(file:)` cross-references visitor data after the walk |
| `SourceKitASTRule` | SourceKit dictionaries | No | Semantic/type-aware checks |
| `CollectingRule` | Two-pass (collect + validate) | No | Cross-file analysis (dead symbols, duplication) |

## Directory Organization

Place rules under `Sources/SwiftiomaticKit/Rules/<Category>/`:

```
Rules/
  AccessControl/    ControlFlow/    DeadCode/        Documentation/
  Frameworks/       Metrics/        Modernization/   Multiline/
  Naming/           Ordering/       Performance/     Redundancy/
  Testing/          TypeSafety/     Whitespace/
```

Each category has subcategories (e.g., `Whitespace/Braces/`, `Whitespace/Punctuation/`).

## Creating a SwiftSyntaxRule

### Minimal lint rule (severity-only options)

```swift
import SwiftSyntax

struct MyNewRule {
  static let id = "my_new_rule"
  static let name = "My New Rule"
  static let summary = "Brief description of what it checks"
  // Override defaults only when needed:
  // static let scope: Scope = .format    // default: .lint
  // static let isOptIn = true            // default: false (enabled by default)
  // static let isCorrectable = true      // default: false

  static var nonTriggeringExamples: [Example] {
    [
      Example("let x = 1"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("let x = ↓1"),  // ↓ marks violation position
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension MyNewRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension MyNewRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: SomeNodeSyntax) {
      if violationCondition {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
```

### Making it correctable (add Rewriter)

Add to struct: `static let isCorrectable = true`

Add corrections map:
```swift
static var corrections: [Example: Example] {
  [
    Example("let x = ↓1"): Example("let x = 1"),
  ]
}
```

Add rewriter to SwiftSyntaxRule extension:
```swift
func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
  Rewriter(configuration: options, file: file)
}
```

Add Rewriter class:
```swift
fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
  override func visit(_ node: SomeNodeSyntax) -> SomeNodeSyntax {
    guard violationCondition else { return super.visit(node) }
    guard !isDisabled(atStartPositionOf: node) else { return super.visit(node) }
    numberOfCorrections += 1
    return transformedNode
  }
}
```

**Rewriter rules:**
- Override `visit()` (not `visitPost()`) -- must return the (possibly modified) node
- Always check `isDisabled(atStartPositionOf:)` before correcting
- Increment `numberOfCorrections` for each correction
- Call `super.visit(node)` when not modifying (continues traversal)
- If `requiresSourceKit = true`, corrections only run in `sm lint`/`sm analyze` — `sm format` runs without SourceKit context
- When calling `rule.correct()` outside the `Linter`, wrap in `CurrentRule.$identifier.withValue(type(of: rule).identifier) { ... }`. See `FormatCommand.applyCorrectableLintRules()` for the pattern.

### Alternative: Visitor-based corrections (no Rewriter)

For simple corrections (e.g., replacing trivia between two tokens), skip the Rewriter and collect corrections in the Visitor. Set `isCorrectable = true` but don't implement `makeRewriter()`. The framework uses `compactMap` on violation corrections — violations without corrections are simply skipped.

```swift
violations.append(
  SyntaxViolation(
    position: node.positionAfterSkippingLeadingTrivia,
    reason: "description of the issue",
    correction: SyntaxViolation.Correction(
      start: startPosition,
      end: endPosition,
      replacement: "fixed code"
    ),
  ),
)
```

This is ideal when only some violations in a rule are correctable (e.g., an existing lint rule getting a new correctable option).

## Custom Options

When a rule needs configuration beyond severity, create a separate options file:

```swift
// MyNewOptions.swift
struct MyNewOptions: SeverityBasedRuleOptions {
  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>(.warning)

  @OptionElement(key: "max_width")
  private(set) var maxWidth = 120

  @OptionElement(key: "mandatory")
  private(set) var mandatory = false

  typealias Parent = MyNewRule

  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$maxWidth.key] {
      try maxWidth.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$mandatory.key] {
      try mandatory.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
```

Then in the rule: `var options = MyNewOptions()`

Access in Visitor/Rewriter via `configuration.maxWidth`.

### FormatAwareRule

To inherit from the global `format:` YAML section (e.g., `format.max_width`):

```swift
extension MyNewRule: FormatAwareRule {
  static var formatConfigKeys: Set<String> { ["max_width"] }
}
```

The `RuleResolver` filters global `formatDefaults` to only declared keys, then merges with per-rule config (per-rule wins). Add matching `@OptionElement(key: "max_width")` to the options struct.

## Typed Violation Messages

For rules with multiple message variants, define `ViolationMessage` factory methods instead of inline strings:

```swift
extension ViolationMessage {
  fileprivate static func tooDeep(_ name: String, threshold: Int) -> Self {
    "\(name) nested deeper than \(threshold) levels"
  }
}
// Usage: violations.append(SyntaxViolation(position: pos, message: .tooDeep("Type", threshold: 2)))
```

## Skipping Nested Scopes

Rules that only care about declarations at the current scope level (top-level, member-level, etc.) must skip three block types that introduce nested local scopes:

| Syntax Node | Where It Appears |
|-------------|------------------|
| `CodeBlockSyntax` | Function/method bodies, `if`/`for`/`while` bodies |
| `ClosureExprSyntax` | Closure literals `{ ... }` |
| `AccessorBlockSyntax` | Computed property and subscript bodies (`var foo: T { ... }`) |

**Use `skipsNestedScopes`** — a single `Bool` property on `ViolationCollectingVisitor` that structurally skips all three together. This prevents the common bug of skipping `CodeBlockSyntax` but forgetting `AccessorBlockSyntax`.

```swift
fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skipsNestedScopes: Bool { true }

    override func visitPost(_ node: VariableDeclSyntax) {
        // Only sees top-level/member-level declarations — code blocks,
        // accessor blocks, and closures are automatically skipped.
    }
}
```

The flag works for both execution paths:
- **Pipeline rules**: `LintPipeline` reads the flag at init and manages `skipDepths` automatically (same mechanism as `skippableDeclarations`)
- **Fallback rules**: Base class provides default `visit(_:)` overrides for all three types

**Do NOT manually override `visit(_: CodeBlockSyntax)` etc. just to return `.skipChildren`.** Use `skipsNestedScopes` instead. Manual overrides are only appropriate when you need custom logic at the scope boundary (e.g., pushing/popping state).

## Examples

- `↓` marks where the violation position should be reported
- `nonTriggeringExamples` must produce zero violations
- `triggeringExamples` must produce violations at each `↓` position
- `corrections` maps triggering input to corrected output (both use `↓` in the key)
- Examples are auto-tested wrapped in comments, strings, and with multibyte prefixes
- Skip specific tests with: `.skipWrappingInCommentTest()`, `.skipMultiByteOffsetTest()`, etc.
- Use `.focused()` during development to run only that example

### Examples with custom configuration

Pass `configuration:` to test behavior under non-default options. The dict keys must match `@OptionElement(key:)` keys:

```swift
Example(
  """
  ↓@Test
  func foo() { }
  """,
  configuration: ["inline_when_fits": true, "max_width": 120],
)
```

This lets the test infrastructure apply the configuration before running the example. Use this when a feature is opt-in (default `false`) and examples only trigger when enabled.

Corrections with configuration:
```swift
static var corrections: [Example: Example] {
  [
    Example(
      "↓@Test\nfunc foo() { }",
      configuration: ["inline_when_fits": true, "max_width": 120],
    ): Example(
      "@Test func foo() { }"
    ),
  ]
}
```

## swift-syntax API

For position, trivia, token navigation, file access, and common patterns, see [references/swift-syntax-api.md](references/swift-syntax-api.md). Key project-specific accessors: `locationConverter` (in Visitor/Rewriter), `file.contents`, `file.lines`, `attribute.attributeNameText`.

## SourceKitASTRule

Use only when the check requires resolved types that syntax alone can't determine.

```swift
struct MyRule: SourceKitASTRule {
  static let requiresSourceKit = true
  // KindType can be: SwiftDeclarationKind, ExpressionKind, or StatementKind
  func validate(file: SwiftSource, kind: ExpressionKind, dictionary: SourceKitDictionary)
    -> [RuleViolation]
  {
    // dictionary provides: nameOffset, nameLength, bodyOffset, bodyLength, substructure, etc.
  }
}
```

## CollectingRule (Cross-File)

Use only for cross-file checks (e.g., unused declarations across a module).

```swift
struct MyRule: CollectingRule {
  typealias FileInfo = [String: Set<String>]  // Collected data type

  func collectInfo(for file: SwiftSource) -> FileInfo {
    // Pass 1: gather declarations/references from each file
  }

  func validate(file: SwiftSource, collectedInfo: [SwiftSource: FileInfo]) -> [RuleViolation] {
    // Pass 2: validate using aggregated info from all files
  }
}
```

## Registration and Testing

After creating, renaming, or removing rule files:

```sh
swift run GeneratePipeline
```

This regenerates:
- `Sources/SwiftiomaticKit/Rules/RuleRegistry+AllRules.generated.swift` (all rule types)
- `Sources/SwiftiomaticKit/Rules/LintPipeline.generated.swift` (optimized visitor dispatch)

**Never edit generated files directly.**

### Automatic testing

`RuleExampleTests` auto-tests all registered rules that:
- Don't require SourceKit
- Don't require compiler arguments
- Don't use cross-file collection
- Have at least one example

No per-rule test boilerplate needed. Just provide good examples.

Run tests for a specific rule: filter by rule name (e.g., `--filter AttributePlacement`).

## Diagnosing Rule Issues

### Rule doesn't trigger

1. Check `triggeringExamples` -- does the example match what you expect?
2. Verify the Visitor overrides the correct `visitPost()` node type
3. Check that the violation position uses `positionAfterSkippingLeadingTrivia` (not `position`)
4. For SourceKitASTRule: verify the `KindType` matches the AST structure
5. Run `swift run GeneratePipeline` -- rule might not be registered
6. Check `.swiftiomatic.yaml` -- rule might be disabled

### Rule triggers incorrectly (false positive)

1. Add the false positive case to `nonTriggeringExamples`
2. Run tests to confirm it fails
3. Add guard conditions to the Visitor to exclude the case
4. Common exclusions: inside comments, inside strings, conditional bindings, protocol requirements

### Corrections don't apply

1. Verify `static let isCorrectable = true` is set
2. Verify `makeRewriter()` returns non-nil (or corrections are collected in Visitor)
3. In Rewriter: check `isDisabled(atStartPositionOf:)` -- disabled regions skip corrections
4. In Rewriter: verify `numberOfCorrections` is incremented
5. In Rewriter: ensure `super.visit(node)` is called for non-matching cases (continues traversal)

### Pipeline not picking up rule

1. Run `swift run GeneratePipeline`
2. Check `RuleRegistry+AllRules.generated.swift` for the rule type
3. Pipeline-eligible requires: SwiftSyntaxRule, no `preprocess` override, not CollectingRule, not SourceKitASTRule, not `requiresPostProcessing`, and **visitor must reference `violations`** (auto-detected by the generator — if the visitor never appends to `violations`, the rule is routed to the fallback path). `BodyLengthVisitor` subclasses are exempt since the base class appends on their behalf.

### Rule works alone but fails in full RuleExampleTests suite

Swift Testing misattributes failures from `.serialized` parameterized tests — ALL failures report as `identifier_name` (or whichever case is mid-flight) regardless of which rule actually failed. To diagnose:

1. **Don't trust the `(→ rule_name)` label.** Read the violation message and example code to identify the actual failing rule.
2. **Write debug state to `/tmp/` files** — the MCP test runner truncates `#expect` messages and swallows `print()` output.
3. **Common causes of suite-only failures:**
   - **Visitor scope skipping.** Use `override var skipsNestedScopes: Bool { true }` to skip all nested scope blocks (CodeBlock, AccessorBlock, ClosureExpr) together. Don't manually override individual `visit(_:)` methods just to return `.skipChildren`.
   - **Two-pass rules in the pipeline.** If a rule's visitor collects data (e.g., type names) but violations are determined in a custom `validate(file:)` override that post-processes after the walk, the pipeline will report 0 violations (it only reads the visitor's `violations` array). The generator auto-detects this: if the visitor class never references `violations`, the rule is routed to the fallback path. Use `static let requiresPostProcessing = true` as an escape hatch if auto-detection gets it wrong (e.g., the visitor references `violations` for counting but real violations come from post-processing).
   - **Check ordering in multi-branch logic.** Context-specific overrides (after `::` module selector, after `.` member access) must precede blanket checks (e.g., `backtickAlwaysRequired`), or the blanket check short-circuits before the override runs.
4. **`MemberBlockSyntax` vs type declaration nodes.** To check "inside a type body", walk up to `MemberBlockSyntax` — not `ClassDeclSyntax`/`StructDeclSyntax`/`EnumDeclSyntax`, which also match the type NAME position itself.

## Key Reference Files

All paths relative to `Sources/SwiftiomaticKit/`.

| File | Purpose |
|------|---------|
| `Rules/RuleOptions.swift` | `SeverityBasedRuleOptions`, `@OptionElement` macro |
| `Rules/RuleResolver.swift` | Config injection, `FormatAwareRule` merging logic |
| `Support/Visitors/ViolationCollectingVisitor.swift` | `ViolationCollectingVisitor`, `skipsNestedScopes`, `skippableDeclarations` |
| `Extensions/SwiftSyntax+Declarations.swift` | `attributeNameText` and other SwiftSyntax extensions |
