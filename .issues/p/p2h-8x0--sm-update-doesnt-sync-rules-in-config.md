---
# p2h-8x0
title: sm update doesn't sync rules in config
status: completed
type: bug
priority: normal
created_at: 2026-04-25T03:05:59Z
updated_at: 2026-04-25T03:44:23Z
sync:
    github:
        issue_number: "401"
        synced_at: "2026-04-25T03:51:30Z"
---

Running `sm update` is supposed to:
- Add missing rules to `swiftiomatic.json`
- Remove old/deprecated rules from the config
- Warn about misplaced rules

Currently it does none of these.

## Repro
1. Modify `swiftiomatic.json` so it's missing a known rule, contains a non-existent rule, or has a rule in the wrong section.
2. Run `sm update`.
3. Observe: config is unchanged and no warnings are emitted.

## Expected
- Missing rules added with their default values
- Removed/unknown rules stripped (or warned)
- Misplaced rules flagged with a warning

## Tasks
- [x] Add failing test that asserts each behavior (add missing, remove unknown, warn on misplaced)
- [x] Fix `update` command implementation
- [x] Verify all three behaviors pass



## Summary of Changes

Root cause: the diff logic skipped any root key found in `allSettingAndMetaKeys`. The `IndentBlankLines` setting has key `"blankLines"`, which collides with the `blankLines` group name — so the entire `blankLines` group was skipped. This made everything inside it look missing-and-already-handled. Misplaced rules also weren't detected separately from add/remove.

Fix:
- Extracted pure `Configuration.computeUpdate(for:)` returning `UpdateDiff { toAdd, toRemove, misplaced }`.
- Group dispatch now runs **before** the meta-key skip, so a setting key that collides with a group name doesn't suppress the group.
- Misplaced detection: a rule whose qualified key isn't in the registry but whose short key is, is reported as misplaced (with canonical location).
- `apply` moves misplaced rules **preserving user values** (no longer reset to defaults).
- Added `Configuration.qualifiedKeyByShortKey` for short-key → canonical lookup.
- 10 new tests in `ConfigurationUpdateTests.swift` covering all three behaviors plus value preservation and idempotence.

Files:
- `Sources/SwiftiomaticKit/Configuration/Configuration+Update.swift` (new)
- `Sources/SwiftiomaticKit/Configuration/Configuration.swift` (added `qualifiedKeyByShortKey`)
- `Sources/Swiftiomatic/Subcommands/Update.swift` (uses pure diff, prints misplaced section)
- `Tests/SwiftiomaticTests/API/ConfigurationUpdateTests.swift` (new)
