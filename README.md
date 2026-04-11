# Swiftiomatic

AST-accurate Swift linting, formatting, and code analysis, usable from Xcode, command line, and your LLM agent frenemy. This tool derives directly from, and aspires to combine the best of,

- **[SwiftLint](https://github.com/realm/SwiftLint)**
- Nick Lockwood's **[SwiftFormat](https://github.com/nicklockwood/SwiftFormat)**
- Apple's **[swift-format](https://github.com/apple/swift-format)**

My goal here was to address the overlap between linting and formatting. Using *SwiftLint* and *SwiftFormat*, I had to configure and exclude similar rules twice.
```swift
// swiftlint:disable async_without_await
// swiftformat:disable redundantAsync redundantThrows
```

Instead, *Swiftiomatic* has a single set of rules, each configured either to

| Scope | Runs in | What it does |
|---|---|---|
| `.lint` | Xcode Build Phase, `sm lint` | Wrong code, anti-patterns, style violations. Shows warnings and errors in the editor. |
| `.format` | Xcode Editor Extension, `sm format` | Formatting only; whitespace, indentation, brace placement. Never surfaces as a lint warning. |
| `.suggest` | `sm analyze` | Research patterns for nvestigation. Identifies code worth reviewing, not definitive errors. |

Each rule has a separate *auto-fix* property. All `.format` rules are auto-fixable (of course) whereas not all `.lint` rules are auto-fixable.

Scope is the only thing that determines where a rule runs. The rule itself is agnostic (though it flirts with atheism), using the same `SyntaxVisitor`, violation model, and configuration.

This tool is fully Swift 6.3 with strict concurrency and Swift Testing. Any patterns older than about 20 minutes ago were eliminated with vigor.

## Installation

### Homebrew

```sh
brew install toba/tap/sm
```

### Swift Package Manager

Add to your `Package.swift`:

```swift
.package(url: "https://github.com/toba/swiftiomatic.git", from: "0.18.3")
```

SPM plugins are included for both formatting and linting — usable from Xcode or the command line without installing the CLI separately.

## Usage

### CLI

```sh
# Lint (warnings and errors, Xcode-compatible output)
sm lint Sources/

# Format (rewrite files in place)
sm format Sources/

# Analyze (format + lint + suggest in one pass — designed for agents)
sm analyze Sources/ --format json

# List all rules
sm list-rules

# List only format-scope rules
sm list-rules --source format
```

The `analyze` command is the all-in-one mode. It formats first (applying all correctable rules), then reports remaining lint violations and suggestions. Use `--no-fix` if you want diagnostics without file changes.

### Xcode Build Phase

Add a Run Script phase, just like the venerable *SwiftLint*:

```sh
if command -v sm >/dev/null 2>&1; then
    sm lint "$SRCROOT"
else
    echo "warning: sm not found — see https://github.com/toba/swiftiomatic"
fi
```

Warnings and errors appear inline in the editor. Only `.lint`-scoped rules run here.

### Xcode Source Editor Extension

The companion app installs an editor extension that appears under **Editor > Swiftiomatic** with three commands:

- **Format File** — formats the entire buffer
- **Format Selection** — formats selected lines only
- **Lint File** — runs lint rules and shows a summary notification

## Configuration

Drop a `.swiftiomatic.yaml` in your project root:

```yaml
rules:
  disabled:
    - line_length
    - trailing_comma

  enabled:
    - unused_declaration
    - prefer_swift_testing
    - reduce_into

  config:
    cyclomatic_complexity:
      severity: error
```

### Nested Overrides

`.swiftiomatic.yaml` files in subdirectories override the root config for files within that subtree:

```
MyApp/
  .swiftiomatic.yaml          # root: max_width 120
  Sources/
    .swiftiomatic.yaml        # overrides: max_width 80
  Packages/LegacySDK/
    .swiftiomatic.yaml        # inherit: false — starts fresh
```

Child configs deep-merge with their parents. Scalars: child wins. Arrays: child replaces. Nested dicts: merged key by key. Set `inherit: false` to stop the chain entirely.

## Rule Model

Every rule is a `SyntaxVisitor` subclass with two key properties:

1. **Scope** — where it runs (`.lint`, `.format`, or `.suggest`)
2. **Correctable** — whether it can auto-fix what it finds

The interaction between these two properties is the whole trick:

- **Format rules** are always correctable — that's their entire purpose.
- **Correctable lint rules** show warnings in the build phase *and* apply fixes when the formatter runs. Same rule, both audiences.
- **Suggest rules** are never correctable — they flag code for human or agent judgment.

### Categories

The 336 rules span 15 categories:

| Category | Rules | Covers |
|---|---|---|
| Redundancy | 59 | Unnecessary overrides, redundant types, unneeded modifiers |
| Whitespace | 59 | Braces, spacing, line endings, punctuation |
| ControlFlow | 51 | Closures, conditionals, pattern matching, returns |
| Frameworks | 40 | Foundation, SwiftUI, UIKit patterns |
| TypeSafety | 32 | Optionals, correctness, type usage |
| Ordering | 31 | Import sorting, file structure, declaration order |
| Modernization | 31 | Concurrency, legacy API replacement |
| Testing | 31 | XCTest, Swift Testing, Quick/Nimble |
| Multiline | 29 | Alignment, argument wrapping |
| Naming | 23 | Identifier and file naming conventions |
| AccessControl | 23 | Visibility modifiers, access scope |
| Documentation | 21 | Comments, doc annotations, MARK usage |
| Metrics | 19 | Complexity, length thresholds |
| DeadCode | 19 | Unused declarations, duplicate imports |
| Performance | 16 | Collection algorithms, reduce patterns |

### Cross-File Analysis

Some rules — dead symbol detection, structural duplication — need to see more than one file at a time. These use a two-pass architecture: pass 1 collects declarations across all files, pass 2 finds (or fails to find) references. Rules that need SourceKit for type-aware analysis can opt in with `requiresSourceKit`.

## Agent Mode

The `analyze` command exists specifically for LLM agents. It runs the full pipeline — format, lint, suggest — and returns structured JSON:

```json
{
  "ruleID": "typed-throws",
  "source": "lint",
  "severity": "warning",
  "confidence": "high",
  "file": "Sources/Foo.swift",
  "line": 42,
  "column": 5,
  "message": "Function 'parse' throws only ParseError but declares untyped 'throws'",
  "suggestion": "func parse() throws(ParseError)",
  "canAutoFix": true
}
```

Each finding includes a `confidence` level — `high`, `medium`, or `low` — so the agent can triage. Swiftiomatic deliberately errs on the side of false positives. The agent has context we don't (project conventions, intent, history) and can dismiss what doesn't apply. A missed issue is worse than a noisy one.

## Requirements

- macOS 26+
- Swift 6.3

## License

MIT
