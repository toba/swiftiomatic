---
# 3d1-6hi
title: Add `update` subcommand to sync swiftiomatic.json with current rule registry
status: completed
type: feature
priority: normal
created_at: 2026-04-23T16:22:00Z
updated_at: 2026-04-23T16:36:38Z
sync:
    github:
        issue_number: "359"
        synced_at: "2026-04-23T16:37:30Z"
---

## Context

When rules are added or removed, the user's `swiftiomatic.json` becomes stale — it may reference rules that no longer exist or be missing entries for new rules. There's no automated way to bring the config file up to date without regenerating it from scratch (which loses customizations).

## Behavior

`sm update` reads the applicable `swiftiomatic.json` (discovered from CWD via `Configuration.url(forConfigurationFileApplyingTo:)`), compares its `rules` keys against `ConfigurationRegistry.allRuleTypes`, and:

1. Calculates which rules to **add** (in registry but not in config) and **remove** (in config but not in registry)
2. Prints the diff to stdout
3. Prompts user to type "yes" to apply
4. Updates the file in place, preserving all existing values
5. Reports what was added and removed

New rules should be added with their default values. Removed rules are deleted from the JSON.

## Scope

- [x] Create `Sources/Swiftiomatic/Subcommands/Update.swift`
- [x] Register in `SwiftiomaticCommand.subcommands`
- [x] Discover config file from CWD
- [x] Compare config rules against registry
- [x] Show planned additions/removals, prompt for confirmation
- [x] Update file in place preserving existing values
- [x] Report results

## Key files

- `Sources/Swiftiomatic/SwiftiomaticCommand.swift` — register subcommand
- `Sources/SwiftiomaticKit/Configuration/Configuration.swift` — config discovery + parsing
- `Sources/SwiftiomaticKit/Configuration/Configuration+Dump.swift` — JSON serialization
- `Sources/SwiftiomaticKit/Generated/ConfigurationRegistry+Generated.swift` — `allRuleTypes` registry
- `Sources/Swiftiomatic/Subcommands/Doctor.swift` — reference for subcommand pattern


## Summary of Changes

Created `sm update` subcommand that syncs `swiftiomatic.json` with the current rule registry. Works at the JSONValue level to preserve existing values and sort order. Correctly distinguishes rules from layout settings (including grouped settings at root level). Shows planned adds/removes and prompts for confirmation before writing.

Files: `Sources/Swiftiomatic/Subcommands/Update.swift` (new), `SwiftiomaticCommand.swift` (register), `Configuration.swift` (expose rule/setting key metadata).
