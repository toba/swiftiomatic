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
| `SwiftSyntaxRule` + `requiresPostProcessing` | SwiftSyntax AST | No (fallback) | Rules whose `validate(file:)` cross-references visitor data after the walk |
| `SourceKitASTRule` | SourceKit dictionaries | No | Semantic/type-aware checks |
| `CollectingRule` | Two-pass (collect + validate) | No | Cross-file analysis (dead symbols, duplication) |

## Scopes

| Scope | Runs in | Purpose |
|-------|---------|---------|
| `.lint` | Xcode Build Phase, `sm lint` | Wrong code, anti-patterns, style violations |
| `.format` | Xcode Editor Extension, `sm format` | Whitespace, indentation, brace placement. Always correctable |
| `.suggest` | `sm suggest` | Research patterns for agent review. Never correctable |

### SourceKit and format corrections

`sm format` filters out rules where `requiresSourceKit = true`. If a rule is both correctable and SourceKit-dependent (e.g., `UnusedImportRule`, `ExplicitSelfRule`), its corrections only apply during `sm lint` or `sm analyze` — never during `sm format`. This is because format runs without compiler arguments or SourceKit context.

When calling `rule.correct()` outside the `Linter` (e.g., in CLI commands), wrap calls in `CurrentRule.$identifier.withValue(type(of: rule).identifier) { ... }` to set the rule execution context. Without this, any SourceKit request triggers a stderr warning. See `FormatCommand.applyCorrectableLintRules()` and `Linter.correct(using:)` for the correct pattern.

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
- If the rule also sets `requiresSourceKit = true`, corrections only run in `sm lint`/`sm analyze`, not `sm format`

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

For rules with multiple message variants, define typed messages:

```swift
extension ViolationMessage {
  fileprivate static func tooDeep(_ name: String, threshold: Int) -> Self {
    "\(name) nested deeper than \(threshold) levels"
  }
}
```

Use in visitor:
```swift
violations.append(SyntaxViolation(
  position: node.positionAfterSkippingLeadingTrivia,
  message: .tooDeep("Type", threshold: 2)
))
```

## Visitor Skip Gotchas

When overriding `visit()` to return `.skipChildren` for scope boundaries, remember that Swift uses **three distinct block types** for code bodies:

| Syntax Node | Where It Appears |
|-------------|------------------|
| `CodeBlockSyntax` | Function/method bodies, `if`/`for`/`while` bodies |
| `ClosureExprSyntax` | Closure literals `{ ... }` |
| `AccessorBlockSyntax` | Computed property and subscript bodies (`var foo: T { ... }`) |

If your rule skips `CodeBlockSyntax` to avoid walking into local scopes, you almost certainly need to also skip `AccessorBlockSyntax` and `ClosureExprSyntax`. Missing `AccessorBlockSyntax` is a common bug — the rule works on simple examples but fails on computed properties.

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

## swift-syntax API Quick Reference

Key APIs used in Visitor/Rewriter implementations:

### Position & Location

```swift
// SourceLocationConverter — available as `locationConverter` in Visitor/Rewriter
let loc = locationConverter.location(for: node.positionAfterSkippingLeadingTrivia)
loc.line    // Int (1-based, NON-optional)
loc.column  // Int (1-based, NON-optional)

// Key position properties on syntax nodes:
node.position                          // AbsolutePosition — start including leading trivia
node.positionAfterSkippingLeadingTrivia // AbsolutePosition — start of actual text
node.endPosition                       // AbsolutePosition — end including trailing trivia
node.endPositionBeforeTrailingTrivia    // AbsolutePosition — end of actual text
```

### Trivia Manipulation

```swift
// Read trivia
token.leadingTrivia     // Trivia before the token text
token.trailingTrivia    // Trivia after the token text
trivia.pieces           // [TriviaPiece] — individual pieces (spaces, newlines, comments)
trivia.containsNewlines()  // helper extension
trivia.containsComments    // helper extension

// Modify trivia (returns new node — SwiftSyntax is immutable)
token.with(\.leadingTrivia, .space)          // single space
token.with(\.leadingTrivia, Trivia(pieces: newPieces))
token.with(\.trailingTrivia, [])             // remove all

// Common trivia values
Trivia.space                     // single space
Trivia.newline                   // single newline
Trivia(pieces: [.spaces(4)])     // 4 spaces
```

### Token Navigation

```swift
node.lastToken(viewMode: .sourceAccurate)    // last token in a syntax node
token.nextToken(viewMode: .sourceAccurate)    // next token in the source
token.previousToken(viewMode: .sourceAccurate)
```

### File Access

```swift
// In Visitor/Rewriter, `file` is the SwiftSource instance
file.contents         // String — full source text
file.lines            // [Line] — parsed lines (0-based array, but Line.index is 1-based)
file.lines[n - 1].content  // String — text of line n (no newline terminator)
file.stringView       // StringView — optimized string operations
```

### Common Patterns

**Replace trivia between two tokens** (e.g., collapse newline+indent to space):
```swift
let lastToken = node.lastToken(viewMode: .sourceAccurate)!
let nextToken = lastToken.nextToken(viewMode: .sourceAccurate)!
let correction = SyntaxViolation.Correction(
  start: lastToken.endPositionBeforeTrailingTrivia,
  end: nextToken.positionAfterSkippingLeadingTrivia,
  replacement: " ",
)
```

**Compute line width** (for max_width checks):
```swift
let loc = locationConverter.location(for: node.positionAfterSkippingLeadingTrivia)
let indent = loc.column - 1  // 0-based column
let lineContent = file.lines[loc.line - 1].content
let strippedLength = lineContent.drop(while: { $0 == " " || $0 == "\t" }).count
```

**Check attribute properties**:
```swift
// AttributeSyntax
attribute.attributeNameText     // String, e.g. "Test" (extension in SwiftSyntax+Declarations.swift)
attribute.arguments             // nil if no arguments, non-nil for @Test(.tags(...))
attribute.trimmedDescription    // "@Test" — text without surrounding trivia

// AttributeListSyntax
node.children(viewMode: .sourceAccurate).compactMap { $0.as(AttributeSyntax.self) }
```

## SourceKitASTRule

For rules needing SourceKit's pre-typechecked AST:

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
3. Pipeline-eligible requires: SwiftSyntaxRule, no `preprocess` override, not CollectingRule, not SourceKitASTRule, not `requiresPostProcessing`

### Rule works alone but fails in full RuleExampleTests suite

Swift Testing misattributes failures from `.serialized` parameterized tests — ALL failures report as `identifier_name` (or whichever case is mid-flight) regardless of which rule actually failed. To diagnose:

1. **Don't trust the `(→ rule_name)` label.** Read the violation message and example code to identify the actual failing rule.
2. **Write debug state to `/tmp/` files** — the MCP test runner truncates `#expect` messages and swallows `print()` output.
3. **Common causes of suite-only failures:**
   - **Visitor skips missing a node type.** `CodeBlockSyntax` ≠ `AccessorBlockSyntax` — computed property bodies use `AccessorBlockSyntax`. If your visitor skips `CodeBlockSyntax` to avoid entering function bodies, also skip `AccessorBlockSyntax` and `ClosureExprSyntax`.
   - **Two-pass rules in the pipeline.** If a rule's visitor collects data (e.g., type names) but violations are determined in a custom `validate(file:)` override that post-processes after the walk, the pipeline will report 0 violations (it only reads the visitor's `violations` array). Mark with `static let requiresPostProcessing = true` so the generator routes it to the fallback path.
   - **Check ordering in multi-branch logic.** Context-specific overrides (after `::` module selector, after `.` member access) must precede blanket checks (e.g., `backtickAlwaysRequired`), or the blanket check short-circuits before the override runs.
4. **`MemberBlockSyntax` vs type declaration nodes.** To check "inside a type body", walk up to `MemberBlockSyntax` — not `ClassDeclSyntax`/`StructDeclSyntax`/`EnumDeclSyntax`, which also match the type NAME position itself.

## Default Values Reference

```swift
static var scope: Scope { .lint }
static var isCorrectable: Bool { false }
static var isOptIn: Bool { false }          // false = enabled by default
static var isDeprecated: Bool { false }
static var requiresSourceKit: Bool { false }
static var isCrossFile: Bool { false }
static var requiresFileOnDisk: Bool { false }
static var minSwiftVersion: SwiftVersion { .v6 }
static var deprecatedAliases: Set<String> { [] }
static var relatedRuleIDs: [String] { [] }
static var nonTriggeringExamples: [Example] { [] }
static var triggeringExamples: [Example] { [] }
static var corrections: [Example: Example] { [:] }
```

## Key Reference Files

| File | Purpose |
|------|---------|
| `Rules/Rule.swift` | Core `Rule` protocol, `FormatAwareRule` protocol |
| `Rules/RuleOptions.swift` | `RuleOptions`, `SeverityBasedRuleOptions`, `@OptionElement` |
| `Rules/RuleResolver.swift` | Config injection, `FormatAwareRule` merging logic |
| `Rules/SwiftSyntaxRule.swift` | `SwiftSyntaxRule` protocol, `ViolationCollectingRewriter` base class |
| `Support/Visitors/ViolationCollectingVisitor.swift` | `ViolationCollectingVisitor` base class |
| `Models/SyntaxViolation.swift` | `SyntaxViolation`, `Correction`, append helpers |
| `Models/Example.swift` | `Example` struct with `configuration:` parameter |
| `Models/SwiftSource.swift` | `SwiftSource` — `contents`, `lines`, `stringView` |
| `SourceKit/Line.swift` | `Line` struct — `index` (1-based), `content` (String) |
| `Extensions/SwiftSyntax+Declarations.swift` | `attributeNameText` and other SwiftSyntax extensions |
