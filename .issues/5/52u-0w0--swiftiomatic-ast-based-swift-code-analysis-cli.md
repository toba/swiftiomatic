---
# 52u-0w0
title: 'Swiftiomatic: AST-based Swift code analysis CLI'
status: completed
type: epic
priority: normal
created_at: 2026-02-27T21:32:03Z
updated_at: 2026-04-10T22:23:47Z
sync:
    github:
        issue_number: "59"
        synced_at: "2026-04-11T01:01:46Z"
---

Build a swift-syntax CLI tool that performs AST-accurate Swift code analysis across 8 categories derived from the swift-review skill. Replaces grep-based heuristics with structural analysis that eliminates false positives and enables checks grep cannot do.

## Motivation

The swift-review scanner (`swift-review-scan.sh`) uses ripgrep patterns across 8 categories:
1. Generic consolidation & Any elimination
2. Typed throws candidates
3. Structured concurrency / GCD modernization
4. Swift 6.2 modernization
5. Performance anti-patterns
6. Naming heuristics
7. Observation framework pitfalls
8. Agent review candidates (lower-confidence flags)

Grep works well for simple pattern matching (§1-§3, §6) but has fundamental limitations:
- **~15-40% false positive rate** on §8 checks (dead symbols, fire-and-forget Tasks)
- **Cannot detect structural duplication** — needs AST diff on function bodies
- **Cannot trace scope** — can't distinguish a `private func` called locally vs. truly dead
- **Cannot analyze types** — can't verify if a `nonisolated(unsafe) let` value is actually Sendable
- **Cannot reason about control flow** — can't tell if a `Task {}` result is captured in a parent scope

swift-syntax provides the full syntax tree, enabling definitive answers where grep can only flag candidates.

## Architecture

```
swiftiomatic/
├── Package.swift              # swift-syntax 601.0.1+, swift-argument-parser
├── Sources/
│   ├── Swiftiomatic/          # CLI entry point (@main, ArgumentParser)
│   ├── Analysis/              # Core analysis engine
│   │   ├── Analyzer.swift     # Orchestrator: parse → walk → collect → report
│   │   ├── Finding.swift      # Finding model (category, severity, location, message)
│   │   └── Category.swift     # The 8 analysis categories as an enum
│   ├── Checks/                # One SyntaxVisitor per check
│   │   ├── AnyElimination.swift
│   │   ├── TypedThrows.swift
│   │   ├── ConcurrencyModernization.swift
│   │   ├── Swift62Modernization.swift
│   │   ├── PerformanceAntiPatterns.swift
│   │   ├── NamingHeuristics.swift
│   │   ├── ObservationPitfalls.swift
│   │   ├── DeadSymbols.swift
│   │   ├── FireAndForgetTasks.swift
│   │   ├── StructuralDuplication.swift
│   │   └── SwiftUILayout.swift
│   └── Output/                # Formatters
│       ├── TextFormatter.swift    # Human-readable (matches current scanner output)
│       ├── JSONFormatter.swift    # Machine-readable for agent consumption
│       └── SARIFFormatter.swift   # IDE integration (future)
└── Tests/
    └── SwiftiomaticTests/
        ├── Fixtures/          # Small .swift files with known issues
        └── *Tests.swift       # One test file per check
```

## Output contract

JSON output per finding:
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

Text output matches the existing scanner format (§ headers, file:line references, summary counts) so the swift-review skill can swap in swiftiomatic with zero workflow changes.

## Key design decisions

- [ ] Each check is a standalone `SyntaxVisitor` subclass — easy to add/remove checks
- [ ] Two-pass architecture for cross-file checks (dead symbols, duplication): pass 1 collects declarations, pass 2 finds references
- [ ] Confidence levels replace the 🔍/⚡ markers: `high` (definitive), `medium` (likely true), `low` (needs human review)
- [ ] Exclusion patterns (`.build/`, `GRDB/`, `*.generated.swift`) built into file discovery, not regex
- [ ] No type-checking — swift-syntax is syntax-only. Type-aware checks note this limitation explicitly

## Summary of Changes

All 8 analysis categories implemented as SyntaxVisitor checks:

1. **AnyEliminationCheck** — Any/AnyObject type annotations, [String: Any] dictionaries, force casts
2. **TypedThrowsCheck** — Functions throwing single error type with untyped throws
3. **ConcurrencyModernizationCheck** — Completion handlers, DispatchQueue, locks, @unchecked Sendable
4. **Swift62ModernizationCheck** — Task.detached, weak var→let, UnsafeBufferPointer→Span, didSet
5. **PerformanceAntiPatternsCheck** — Date() timing, mutation during iteration, empty array literals
6. **NamingHeuristicsCheck** — Bool naming, factory methods, protocol -able/-ing
7. **ObservationPitfallsCheck** — withObservationTracking, missing weak self in Observations
8. **AgentReviewCheck + FireAndForgetTaskCheck + SwiftUILayoutCheck + DeadSymbolsCheck + StructuralDuplicationCheck** — Full §8 coverage

Cross-file checks: dead private symbols (two-pass), structural code duplication (AST fingerprinting)

CLI: scan, list-checks subcommands, --format text|json, --category, --min-confidence, --min-severity, --quiet

8 tests passing across 3 test suites with fixture files.

Two tasks remain in review: swift-review skill integration and Homebrew tap setup.
