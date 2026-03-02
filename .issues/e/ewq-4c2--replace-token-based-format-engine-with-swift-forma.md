---
# ewq-4c2
title: Replace token-based format engine with swift-format pretty-printer
status: review
type: feature
priority: high
created_at: 2026-03-02T21:40:56Z
updated_at: 2026-03-02T23:46:42Z
parent: a2a-2wk
sync:
    github:
        issue_number: "140"
        synced_at: "2026-03-02T23:47:35Z"
---

Import swift-format's Oppen-style pretty-printer as a replacement for the iterative token-based FormatEngine.

## Current State
- `Sources/Swiftiomatic/Format/` — 20 files, ~17,800 lines
- Token-based engine: tokenize → apply rules iteratively (up to 10 passes) → reconstitute
- Iterative convergence is expensive and fragile (rules can conflict)
- No real line-breaking algorithm — relies on rule iteration to settle

## Target State
- Import swift-format's `TokenStreamCreator` (~4,800 lines), `PrettyPrint` (~900 lines), `WhitespaceLinter` (~500 lines), and `Token` types
- These take a swift-syntax tree in and produce formatted text out — clean boundary
- Wire as the formatting backend for `swiftiomatic format` and the format phase of `analyze`
- Delete the old `FormatEngine`, `FormatPipeline`, `Tokenizer`, iterative loop

## Tasks
- [x] Study swift-format pretty-printer boundary: inputs, outputs, configuration surface
- [ ] Copy `TokenStreamCreator.swift`, `PrettyPrint.swift`, `WhitespaceLinter.swift`, `Token.swift` into Sources
- [ ] Adapt imports and namespace to Swiftiomatic module
- [ ] Map swift-format's `Configuration` formatting options to swiftiomatic's YAML config
- [ ] Wire pretty-printer into `swiftiomatic format` command
- [ ] Wire into `analyze` command's format phase
- [ ] Migrate existing format rule behaviors that have no pretty-printer equivalent to SwiftSyntaxCorrectableRule
- [ ] Delete old FormatEngine, FormatPipeline, Tokenizer, Token, iterative infrastructure
- [ ] Delete old Format/RuleRegistry.generated.swift
- [ ] Update tests — replace Format/ tests with pretty-printer integration tests
- [ ] Verify `swiftiomatic format` produces equivalent or better output on test corpus


## Summary of Changes

Replaced the token-based format engine (~17,800 lines across 20 files + 128 token-based rule files) with swift-format's Oppen-style pretty-printer.

### What changed
- **Package.swift**: swift-syntax pinned to branch: main, added swift-format dependency
- **FormatEngine.swift**: Rewritten to wrap SwiftFormatter and SwiftLinter from swift-format
- **FormatFinding**: New type replacing Formatter.Change for format lint diagnostics
- **FormatEngineConfiguration**: New public config struct mapping YAML options to swift-format
- **Configuration.swift**: Updated YAML schema with new format keys (max_width, maximum_blank_lines, line_break_before_control_flow_keywords, line_break_before_each_argument, trailing_commas)
- **FormatCommand.swift**: Simplified to use new FormatEngine API
- **RuleCatalog.swift**: Removed old token-based format rule bridging
- **Version.swift + SwiftKeywords.swift**: Extracted from deleted Format/ files into Support/

### What was deleted
- 19 Format/ engine files (Token, Tokenizer, Formatter, FormatPipeline, etc.)
- 128 token-based format rule files in Rules/
- FormatRuleConfigurationAdapter.swift
- 22 old Format/ test files + 150 token-based rule test files + FormatTestHelper.swift

### New tests
- SwiftFormatSmokeTests (3 tests)
- FormatEngineTests (13 tests)
- FormatConfigurationTests (5 tests)

### Build verification
- swift build compiles cleanly
- swift test passes (352 tests)
