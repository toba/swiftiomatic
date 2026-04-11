---
# u99-63l
title: Config and inline comment migration tool
status: completed
type: feature
priority: high
created_at: 2026-04-10T22:25:29Z
updated_at: 2026-04-10T22:45:00Z
parent: pms-xpz
sync:
    github:
        issue_number: "165"
        synced_at: "2026-04-11T01:01:48Z"
---

Provide a `migrate` subcommand that:

1. Detects and converts `.swiftlint.yml` and `.swiftformat` config files to `.swiftiomatic.yaml`
2. Walks the source tree and replaces inline `swiftlint:disable`/`swiftformat:disable` comments with `sm:disable` equivalents

```bash
# Migrate config files
swiftiomatic migrate --config .swiftlint.yml -o .swiftiomatic.yaml

# Migrate inline comments in source files
swiftiomatic migrate --comments Sources/

# Do both
swiftiomatic migrate --config .swiftlint.yml --comments Sources/ -o .swiftiomatic.yaml
```

## Tasks

- [x] Build mapping table of SwiftLint rule IDs → Swiftiomatic rule IDs
- [x] Build mapping table of SwiftFormat rule names → Swiftiomatic rule IDs
- [x] Parse `.swiftlint.yml` (disabled_rules, opt_in_rules, included/excluded, severity overrides)
- [x] Parse `.swiftformat` (--rules, --disable, --enable, formatting options)
- [x] Convert per-rule configuration where possible
- [x] Emit warnings for rules with no Swiftiomatic equivalent
- [x] Write output as valid `.swiftiomatic.yaml`
- [x] Walk source tree replacing `swiftlint:disable` → `sm:disable` inline comments
- [x] Walk source tree replacing `swiftformat:disable` → `sm:disable` inline comments
- [x] Handle `swiftlint:disable:next`, `:this`, `:previous` modifiers
- [x] Add `MigrateCommand` to CLI
- [x] Add tests for config migration
- [x] Add tests for inline comment migration


## Summary of Changes

Created 6 new files:
- `Sources/Swiftiomatic/Migration/RuleMapping.swift` — maps SwiftLint/SwiftFormat rule IDs to Swiftiomatic equivalents (exact, renamed, removed, unmapped)
- `Sources/Swiftiomatic/Migration/SwiftLintConfigParser.swift` — parses `.swiftlint.yml` YAML config
- `Sources/Swiftiomatic/Migration/SwiftFormatConfigParser.swift` — parses `.swiftformat` INI-style config
- `Sources/Swiftiomatic/Migration/ConfigMigrator.swift` — converts parsed configs to `.swiftiomatic.yaml` with merge support
- `Sources/Swiftiomatic/Migration/InlineCommentMigrator.swift` — walks source tree replacing `swiftlint:`/`swiftformat:` comments with `sm:` equivalents
- `Sources/SwiftiomaticCLI/MigrateCommand.swift` — `swiftiomatic migrate` CLI subcommand with auto-detection, dry-run, and JSON output

Created 4 test files (60 tests total):
- `Tests/SwiftiomaticTests/Migration/RuleMappingTests.swift`
- `Tests/SwiftiomaticTests/Migration/SwiftLintConfigParserTests.swift`
- `Tests/SwiftiomaticTests/Migration/SwiftFormatConfigParserTests.swift`
- `Tests/SwiftiomaticTests/Migration/ConfigMigratorTests.swift`
- `Tests/SwiftiomaticTests/Migration/InlineCommentMigratorTests.swift`

Modified 1 file:
- `Sources/SwiftiomaticCLI/SwiftiomaticCLI.swift` — registered `MigrateCommand` in subcommands
