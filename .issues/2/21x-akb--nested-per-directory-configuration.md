---
# 21x-akb
title: Nested per-directory configuration
status: completed
type: feature
priority: normal
created_at: 2026-04-10T22:25:29Z
updated_at: 2026-04-10T23:06:13Z
parent: pms-xpz
sync:
    github:
        issue_number: "169"
        synced_at: "2026-04-11T01:01:47Z"
---

Support \`.swiftiomatic.yaml\` files in subdirectories that override the root config for files within that subtree. This is essential for monorepos where different modules have different conventions.

```
MyApp/
  .swiftiomatic.yaml          # root config
  Sources/
    .swiftiomatic.yaml         # overrides for main app
  Packages/LegacySDK/
    .swiftiomatic.yaml         # relaxed rules for legacy code
```

## Tasks

- [x] Walk parent directories to collect config chain (leaf → root)
- [x] Define merge semantics (child overrides parent; arrays replace, not append)
- [x] Cache resolved configs per directory to avoid redundant parsing
- [x] Support \`inherit: false\` to ignore parent configs entirely
- [x] Add tests for config inheritance and override behavior
- [x] Document nesting behavior


## Summary of Changes

Added `ConfigurationResolver` that resolves per-directory configuration by walking the `.swiftiomatic.yaml` chain from a file's directory up to the project root.

### New files
- `Sources/Swiftiomatic/Configuration/ConfigurationResolver.swift` — chain collection, YAML deep-merge, per-directory caching
- `Tests/SwiftiomaticTests/Configuration/ConfigurationResolverTests.swift` — 16 tests covering merge semantics, chain collection, `inherit: false`, caching

### Modified files
- `Sources/Swiftiomatic/Configuration/Configuration.swift` — extracted `loadUnified(from:)` dict overload, made `loadYAML` internal
- `Sources/SwiftiomaticCLI/SwiftiomaticCLI.swift` — Analyze uses `ConfigurationResolver` for per-file format config
- `Sources/SwiftiomaticCLI/FormatCommand.swift` — FormatCommand uses `ConfigurationResolver` for per-file format config

### Design decisions
- Full chain merge (unlike SwiftLint's single-nested or swift-format's first-match-wins)
- Deep-merge for nested dicts (format, rules.config), full replacement for arrays (rules.enabled, rules.disabled)
- `inherit: false` stops the walk and ignores all parent configs
- Explicit `--config` flag bypasses chain resolution entirely
- Lint rule resolution still uses the base (root) config since cross-file rules need consistent rule sets


### Bonus fix
- Fixed `isCorrectable` and `isCrossFile` not being protocol requirements on `Rule`, causing static dispatch through existentials (always returning `false`). This fixed 3 pre-existing `RuleFilterTests` failures.
