# Swiftiomatic

AST-accurate Swift linting, formatting, and code analysis — used from Xcode, the command line, and by LLM agents.

## Important Agent Rules

- Always create a jig issue before beginning work
- Update the jig issue continuously as you work
- Always use the xc-mcp services to run tests and update projects
- Never git stash to avoid an error — FIX the error

## How It's Used

Swiftiomatic has three audiences. The same rules power all of them.

### 1. Xcode Build Phase (lint)

Works exactly like SwiftLint — add a Run Script phase:

```sh
if command -v swiftiomatic >/dev/null 2>&1; then
    swiftiomatic lint "$SRCROOT"
else
    echo "warning: swiftiomatic not found — see https://github.com/toba/swiftiomatic"
fi
```

Xcode displays warnings and errors inline in the editor. Only rules with scope `.lint` run here.

### 2. Xcode Source Editor Extension (format)

Installs as an Xcode plugin that appears in **Editor > Swiftiomatic** with commands like "Format File", "Format Selection". Applies automatic corrections from all correctable rules.

Also available from the CLI: `swiftiomatic format`.

### 3. Agent Analysis (analyze)

The all-in-one command for LLM agents. It auto-formats, lints, and surfaces suggestions in a single pass:

```sh
swiftiomatic analyze Sources/ --format json
```

What it does:

1. **Formats** — applies all correctable rules (`.format` + correctable `.lint`), rewriting files in place. Use `--no-fix` to report only.
2. **Lints** — returns remaining `.lint` issues with their severity (warning/error).
3. **Suggests** — returns `.suggest` issues: research patterns for the agent to investigate.

The JSON response includes both lint and suggest findings, distinguished by their `scope` field. The agent uses severity, confidence, and scope to prioritize what to act on.

## Philosophy

Swiftiomatic **always errs on the side of false positives**. The calling agent has context the tool does not (project conventions, intent, history) and can dismiss findings that don't apply. A missed issue is worse than a noisy one — the agent can filter, but it can't find what was never reported.

## Rule Model

Every check is a **rule**. Rules are standalone `SyntaxVisitor` subclasses with two key properties:

### Scope

Where the rule participates. Every rule declares exactly one scope:

| Scope | Runs in | Purpose |
|---|---|---|
| **`.lint`** | Xcode Build Phase, `swiftiomatic lint` | Definitive checks — wrong code, anti-patterns, style violations. Shows warnings/errors in the editor. |
| **`.format`** | Xcode Editor Extension, `swiftiomatic format` | Formatting only — whitespace, indentation, brace placement. Never appears as a lint warning. |
| **`.suggest`** | `swiftiomatic suggest` | Research patterns for agent investigation. Identifies code worth reviewing, not exact errors. Never part of lint or format runs on their own. |

### Correctable

Whether the rule can automatically rewrite the code it flags.

- **Correctable lint rules** show warnings in the Build Phase *and* apply their fixes when the formatter runs.
- **Format rules** are always correctable (that's their whole purpose).
- **Suggest rules** are never correctable — they require human or agent judgment.

When the formatter runs (Editor Extension or CLI), it applies corrections from all correctable rules in scope: all `.format` rules plus correctable `.lint` rules.

## Architecture

- **swift-syntax** for AST-accurate analysis — no grep heuristics
- **swift-argument-parser** CLI with subcommands: `lint`, `format`, `analyze` (format + lint + suggest in one pass), `list-rules`, `generate-docs`
- Two-pass architecture for cross-file checks (dead symbols, duplication): pass 1 collects declarations, pass 2 finds references
- Optional SourceKit enrichment for type-aware rules
- YAML configuration (`.swiftiomatic.yaml`) for per-project rule settings
- Installable via Homebrew

## Rule Categories

Rules span these areas regardless of scope:

- Generic consolidation & `Any` elimination
- Typed throws candidates
- Structured concurrency / GCD modernization
- Swift 6.2 modernization
- Performance anti-patterns
- Naming heuristics (Swift API Design Guidelines)
- Observation framework pitfalls

## Swift & Build Settings

- swift-tools-version: 6.2
- `.swiftLanguageMode(.v6)`
- `.enableExperimentalFeature("StrictConcurrency")`
- macOS 15+

## Output

JSON output per finding:

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

Text output also available for human readability.

Confidence levels: `high` (definitive), `medium` (likely true), `low` (needs review). All levels are reported — the consumer decides what to act on.
