# SwiftiomaticKit

The core library for AST-accurate Swift linting and formatting.

## What It Does

Parses Swift source files into syntax trees (via swift-syntax), applies every configured format rule to normalize them, and emits lint findings. This is the engine behind the `sm` CLI, the SPM plugins, and direct API consumers.

## Pipeline

Formatting is two stages:

1. **Stage 1 — `CompactSyntaxRewriter`**: a single tree walk that dispatches every `StaticFormatRule` (modifier order, redundant-self stripping, doc-comment conversion, accessor order, semicolon removal, etc.).
2. **Stage 2 — Structural passes** (≤9): reshapers that need a settled tree (`SortImports`, blank-line policy, `ExtensionAccessLevel`, `FileScopedDeclarationPrivacy`, `FileHeader`, `CaseLet`, …). Each is its own ordered pass.
3. **Pretty-print** (`LayoutCoordinator`): an Oppen-style token-stream printer that decides line breaks and indentation based on the configured line length.

Linting walks the tree once via `LintPipeline`, interleaving every active lint rule per node.

## Structure

| Directory | Purpose |
|---|---|
| `Configuration/` | JSON config (de)serialization, schema validation, type-erased value store |
| `Extensions/` | swift-syntax helpers and small utility extensions |
| `Findings/` | `Finding`, `FindingEmitter`, finding categories |
| `Generated/` | Build-plugin output (`Pipelines+Generated.swift`, `CompactSyntaxRewriter+Generated.swift`, `ConfigurationRegistry+Generated.swift`, `TokenStream+Generated.swift`) — never edit by hand |
| `Layout/` | Pretty-print engine: `LayoutCoordinator`, token types, whitespace linter |
| `Rewrites/` | Hand-written `rewrite<NodeType>(_:context:)` free functions invoked by stage 1 |
| `Rules/` | Rule definitions (lint + format), organized by category |
| `Support/` | `Context`, `DebugOptions`, `Selection`, error types |
| `Syntax/` | `SyntaxRule` / `StaticFormatRule` base machinery, lint and rewrite coordinators, `RuleMask`, `RuleState` |

## Key Concepts

- **`SyntaxRule`** -- base protocol for every rule, lint or format.
- **`StaticFormatRule`** -- format rule with a `static transform(_:parent:context:)` (and optional `willEnter`/`didExit` hooks); collected by the build plugin and dispatched from `CompactSyntaxRewriter`.
- **`StructuralFormatRule`** -- the small set of rules that still subclass `SyntaxRewriter` and run as ordered post-stage-1 passes.
- **`LintSyntaxRule`** -- read-only visitor that emits findings via `diagnose()`.
- **`LintPipeline`** -- interleaves lint rules in a single tree walk for efficiency.
- **`LayoutCoordinator`** -- pretty-print engine; handles whitespace, indentation, and line-break decisions after rewrites.
- **`RuleMask`** -- honours `// sm:ignore` comments to suppress findings/rewrites per-line or per-file.

## Where It Fits

This is the main product library. The `sm` CLI and both SPM plugins depend on it. The `Generator` executable (build plugin) imports `GeneratorKit` to introspect rule types and emit the files in `Generated/`. Test targets validate behaviour.
