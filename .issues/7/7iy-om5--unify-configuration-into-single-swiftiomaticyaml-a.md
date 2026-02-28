---
# 7iy-om5
title: 'Unify configuration into single .swiftiomatic.yaml and sm: comment prefix'
status: in-progress
type: feature
priority: high
created_at: 2026-02-28T16:50:59Z
updated_at: 2026-02-28T16:52:06Z
---

## Goal

Replace the two-config-file system (.swiftlint.yml + .swiftiomatic.yaml) with a single `.swiftiomatic.yaml` that configures all three engines (suggest, lint, format). Replace all inline disable/enable comment prefixes from `swiftlint:` and `swiftformat:` to `sm:`.

## Current State

Two separate config systems coexist:

1. **`.swiftlint.yml`** — vendored SwiftLint configuration (262 rules)
   - `Configuration.swift` — main struct, hardcoded `defaultFileName = ".swiftlint.yml"`
   - `Configuration+Parsing.swift` — parses YAML into typed Configuration
   - `Configuration+RulesMode.swift` — rules filtering modes (default, only, all)
   - `Configuration+RulesWrapper.swift` — orchestrates rule merging
   - `Configuration+FileGraph.swift` — nested parent_config/child_config discovery
   - `Configuration+Merging.swift` — parent/child config merging
   - `Configuration+Cache.swift` — in-memory config caching + on-disk lint cache
   - `Configuration+CommandLine.swift` — CLI overrides
   - `Configuration+LintableFiles.swift` — file discovery + parallel linting
   - `Configuration+IndentationStyle.swift` — tabs/spaces enum
   - `Configuration+FileGraphSubtypes.swift` — graph vertex/edge types
   - `RegexConfiguration.swift` — custom regex rule config
   - `SeverityLevelsConfiguration.swift` — threshold-based severity (warning/error)

2. **`.swiftiomatic.yaml`** — Swiftiomatic-specific (`Config.swift`, now at `Configuration/Config.swift`)
   - `rules.enabled`, `rules.disabled`, `rules.config`
   - `suggest.min_confidence`
   - `format.rules.enable`, `format.rules.disable`
   - `format.options.indent`, `format.options.maxwidth`, `format.options.swiftversion`

### Inline comments

- Lint rules use `// swiftlint:disable|enable[:modifier] rule1 rule2`
- Format rules use `// swiftformat:disable|enable rule1 rule2`
- Parsed by `CommandVisitor` (AST-based) and `SwiftLintFile+Regex.swift` (region-based)

## Target State

### Single config file: `.swiftiomatic.yaml`

```yaml
# File inclusion/exclusion
included:
  - Sources/
excluded:
  - Sources/Generated/

# Rule configuration (all engines)
rules:
  enabled: [rule1, rule2]       # opt-in rules
  disabled: [rule3]             # disabled rules
  config:                       # per-rule overrides
    line_length:
      warning: 120
      error: 150
    custom_rule_name:
      regex: 'pattern'
      severity: warning

# Suggest engine
suggest:
  min_confidence: medium

# Format engine
format:
  options:
    indent: '    '
    maxwidth: 100
    swiftversion: '6.2'
```

### Single comment prefix: `sm:`

```swift
// sm:disable force_unwrap
// sm:enable force_unwrap
// sm:disable:next line_length
// sm:disable:this force_cast - Necessary for bridging
```

Same modifier semantics as current (`:this`, `:next`, `:previous`), same trailing comment support (` - reason`).

## Tasks

- [ ] Update `Configuration.defaultFileName` from `.swiftlint.yml` to `.swiftiomatic.yaml`
- [ ] Merge `Config.swift` (SwiftiomaticConfig) fields into `Configuration.swift`
- [ ] Update `Configuration+Parsing.swift` to parse the unified YAML schema
- [ ] Remove `Config.swift` / `SwiftiomaticConfig` struct
- [ ] Update `CommandVisitor.swift` to recognize `sm:` prefix instead of `swiftlint:`
- [ ] Update `SwiftLintFile+Cache.swift` fast-path check from `"swiftlint:"` to `"sm:"`
- [ ] Update `Command.swift` parsing if it has hardcoded prefix logic
- [ ] Update format engine to recognize `sm:disable`/`sm:enable` instead of `swiftformat:disable`/`swiftformat:enable`
- [ ] Update `BlanketDisableCommandRule` and `SuperfluousDisableCommandRule` for new prefix
- [ ] Update tests for new config file name and comment prefix
- [ ] Update `swiftiomatic.swift` `loadConfig()` to use unified Configuration instead of separate SwiftiomaticConfig
- [ ] Remove files that become dead code after unification
- [ ] Clean up `Configuration+FileGraph.swift` — evaluate whether parent_config/child_config nesting is still needed (probably not for v1)
