---
# xud-dpk
title: Merge Suggest + Lint into one analysis engine
status: completed
type: feature
priority: normal
created_at: 2026-02-28T16:19:41Z
updated_at: 2026-02-28T16:35:37Z
---

Replace separate Scan + Lint CLI commands with a single unified Analyze command that runs both suggest checks and lint rules through the Analyzer.

## Tasks
- [x] Create RuleLoader.swift — instantiate lint rules without Configuration
- [x] Expand Analyzer to run lint rules via rule.validate()
- [x] Create unified Analyze command, delete Scan + Lint subcommands
- [x] Delete Lint/ CLI entry point (LintCommand.swift); keep orchestration for test compat
- [x] Fix FormatCommand file discovery to use FileDiscovery
- [x] Extend SwiftiomaticConfig with rules section
- [x] Add format-lint integration + rule deduplication
- [x] Add --fix mode (format write + lint autocorrect)
- [x] Update RuleCatalog to reflect unified engine
- [x] Verify swift build succeeds


## Summary of Changes

### New Files
- `Sources/Swiftiomatic/RuleLoader.swift` — Instantiates lint rules with enable/disable/config support, bypassing Configuration
- `Sources/Swiftiomatic/RuleDeduplication.swift` — Maps lint rules superseded by format rules to avoid duplicate diagnostics

### Modified Files
- `Sources/Swiftiomatic/Suggest/Analyzer.swift` — Expanded to run lint rules (two-pass collect+validate) alongside suggest checks; added `skipSuggest` flag
- `Sources/Swiftiomatic/swiftiomatic.swift` — Unified `Analyze` command (aliases: scan, lint) replaces separate `Scan` + `Lint` subcommands
- `Sources/Swiftiomatic/Config.swift` — Extended with `rules:` section (enabledLintRules, lintRuleConfigs), separate format/suggest sections
- `Sources/Swiftiomatic/Format/FormatCommand.swift` — Uses `FileDiscovery.findSwiftFiles()` instead of local duplicate file discovery
- `Sources/Swiftiomatic/RuleCatalog.swift` — Reflects unified engine; lint rules run through Analyzer

### Deleted Files
- `Sources/Swiftiomatic/Lint/LintCommand.swift` — Old lint CLI entry point
- `Sources/Swiftiomatic/Support/Models/YamlParser.swift` — Moved from Lint/Models/ to Support/Models/

### Architecture
- Single `Analyze` command runs both suggest checks (deep AST) and lint rules (SwiftLint rule protocol) through the Analyzer
- Lint orchestration types (Configuration, Linter, etc.) kept for test infrastructure compatibility
- `--lint-only`, `--suggest-only` flags for filtering
- `--fix` mode: format engine writes + lint correctable rules correct
- `--include-format`: merges format-lint diagnostics with deduplication
- All output unified as `[Diagnostic]` stream (JSON or text)
