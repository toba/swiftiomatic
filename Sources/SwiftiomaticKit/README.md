# Swiftiomatic

The core library for AST-accurate Swift linting, formatting, and code analysis.

## What It Does

Parses Swift source files into syntax trees (via swift-syntax) and applies 100+ rules to lint, format, and suggest improvements. This is the engine behind the `sm` CLI, SPM plugins, and direct API consumers.

## Structure

| Directory | Purpose |
|---|---|
| `Configuration/` | JSON config serialization, defaults, and rule toggles |
| `Core/` | Rule infrastructure, context/finding emission, parsing helpers, and auto-generated pipelines |
| `Formatter/` | `SwiftiomaticFormatter`, `FormatPipeline`, and `SyntaxFormatRule` base class |
| `Linter/` | `SwiftiomaticLinter`, `LintPipeline`, and `SyntaxLintRule` base class |
| `PrettyPrint/` | Token-stream re-indentation and line-breaking engine |
| `Rules/` | All lint and format rule implementations, organized by category |
| `Support/` | `Finding`, `Selection`, error types, and debugging options |

## Key Concepts

- **SyntaxLintRule** -- read-only visitor that emits findings via `diagnose()`.
- **SyntaxFormatRule** -- syntax rewriter that transforms code AND emits findings.
- **LintPipeline** -- interleaves all lint rules in a single tree walk for efficiency.
- **FormatPipeline** -- runs format rules sequentially, each over the full tree.
- **PrettyPrinter** -- handles whitespace, indentation, and line-break decisions after rules run.
- **RuleMask** -- honors `// swiftiomatic-ignore` comments to suppress rules per-line.

## Where It Fits

This is the main product library. The `sm` CLI and both SPM plugins depend on it. The `Generators` target also imports it to introspect rule types at build time. Test targets validate its behavior.
