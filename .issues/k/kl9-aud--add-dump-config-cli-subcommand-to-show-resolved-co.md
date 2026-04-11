---
# kl9-aud
title: Add `dump-config` CLI subcommand to show resolved configuration
status: completed
type: feature
priority: normal
created_at: 2026-04-11T17:53:01Z
updated_at: 2026-04-11T18:00:36Z
sync:
    github:
        issue_number: "178"
        synced_at: "2026-04-11T18:44:01Z"
---

Add a CLI subcommand that dumps the effective/resolved configuration for a given path, similar to swift-format's `dump-effective-configuration`.

This would show the merged result of nested `.swiftiomatic.yaml` files, including which rules are enabled, their severity, and any per-rule options.

Useful for debugging why a rule fires or doesn't fire in a specific directory.

Upstream reference: swiftlang/swift-format `dump-effective-configuration` subcommand (602.0.0)


## Summary of Changes

- **`dump-config` CLI subcommand**: New subcommand that resolves and displays the effective configuration for any given file or directory path, after merging nested `.swiftiomatic.yaml` files.
  - `--format text|json|yaml` output modes
  - `--show-chain` flag to display which config files were merged (leaf → root)
  - `--config` option for explicit config path (bypasses chain resolution)
- **`Configuration.toFullDictionary()`** and **`toFullYAMLString()`**: New public methods that serialize ALL configuration values (including defaults), unlike `toYAMLString()` which only writes non-default values.
- **`ConfigurationResolver.configChain(for:)`**: New public method exposing the config file chain for a given path.
- **7 new tests** in `ConfigurationResolverTests`: cover `configChain`, `toFullDictionary`, and `toFullYAMLString`.

### Files changed
- `Sources/SwiftiomaticCLI/SwiftiomaticCLI.swift` — added `DumpConfig` command + `DumpConfigFormat` enum
- `Sources/SwiftiomaticKit/Configuration/Configuration.swift` — added `toFullDictionary()`, `toFullYAMLString()`
- `Sources/SwiftiomaticKit/Configuration/ConfigurationResolver.swift` — added public `configChain(for:)`
- `Tests/SwiftiomaticTests/Configuration/ConfigurationResolverTests.swift` — 7 new tests
