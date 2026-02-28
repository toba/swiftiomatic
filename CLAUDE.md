# Swiftiomatic

Lint within Xcode, auto-format as an Xcode plugin or CLI, and scan for anti-patterns as a CLI an  LLM agent can call for suggestions requiring further analysis.

## Important Agent Rules

- Always create a jig issue before beginning work
- Update the jig issue continuously as you work
- Never git stash to avoid an error -- FIX the error

## Philosophy

Swiftiomatic **always errs on the side of false positives**. The calling agent has context the tool does not (project conventions, intent, history) and can dismiss findings that don't apply. A missed issue is worse than a noisy one — the agent can filter, but it can't find what was never reported.

## Architecture

- **CLI tool** built with swift-argument-parser, designed for agent consumption (JSON output)
- **swift-syntax** for AST-accurate analysis — no grep heuristics
- Each check is a standalone `SyntaxVisitor` subclass
- Two-pass architecture for cross-file checks (dead symbols, duplication): pass 1 collects declarations, pass 2 finds references
- Installable via Homebrew (`brew install`)

## Analysis Categories

1. Generic consolidation & Any elimination
2. Typed throws candidates
3. Structured concurrency / GCD modernization
4. Swift 6.2 modernization
5. Performance anti-patterns
6. Naming heuristics (Swift API Design Guidelines)
7. Observation framework pitfalls
8. Agent review candidates (lower-confidence flags — still reported, never suppressed)

## Swift & Build Settings

Same strictness as xc-mcp:

- swift-tools-version: 6.2
- `.swiftLanguageMode(.v6)`
- `.enableExperimentalFeature("StrictConcurrency")`
- macOS 15+

## Output

JSON output per finding for agent consumption:
```json
{
  "category": "typed-throws",
  "severity": "medium",
  "file": "Sources/Foo.swift",
  "line": 42,
  "column": 5,
  "message": "Function 'parse' throws only ParseError but declares untyped 'throws'",
  "suggestion": "func parse() throws(ParseError)",
  "confidence": "high"
}
```

Text output also available, matching swift-review skill format for human readability.

Confidence levels: `high` (definitive), `medium` (likely true), `low` (needs review). All levels are reported — the agent decides what to act on.
