---
# e4v-075
title: 'CLI: replace --rules plumbing with --style'
status: completed
type: feature
priority: normal
created_at: 2026-04-28T01:41:23Z
updated_at: 2026-04-28T02:24:06Z
parent: iv7-r5g
blocked_by:
    - o72-vx7
sync:
    github:
        issue_number: "482"
        synced_at: "2026-04-28T02:40:01Z"
---

## Goal

Update the CLI surface to match the style-driven configuration model.

## Changes

- Add `--style <compact|roomy>` to `format`, `lint`, `analyze`, `dump-configuration`.
- Remove or deprecate any rule-toggle flags surfaced today.
- Audit `Sources/Swiftiomatic/Subcommands/` (especially `DumpConfiguration.swift`) and `Sources/Swiftiomatic/Subcommands/*` for references to `rules`.
- Preserve the upstream swift-format CLI contract per CLAUDE.md: `format`, `lint`, `dump-configuration` and all their existing flags must keep working — `--style` is additive.
- `dump-configuration` should output the new schema (style + universal params), not the old rules map.

## Verification

- `sm format --style compact <file>` round-trips.
- `sm dump-configuration` prints the new shape.
- Existing Xcode-invoked `swift-format format --assume-filename ... --lines ...` calls still succeed (regression test or manual smoke).



## Summary of Changes

- Added `--style <compact|roomy>` flag to `ConfigurationOptions` (`Sources/Swiftiomatic/Subcommands/ConfigurationOptions.swift`); inherited by `format`, `lint`, and `dump-configuration` via `@OptionGroup()`.
- Made `Style: ExpressibleByArgument` so ArgumentParser parses raw values directly.
- Threaded the override through `Frontend.processStandardInput()` and `Frontend.openAndPrepareFile()` in `Sources/Swiftiomatic/Frontend/Frontend.swift` — applied after the configuration provider returns, so `--style` wins over any `style` value in the loaded `swiftiomatic.json`.
- Threaded the same override through `DumpConfiguration.run()` so `sm dump-configuration --style roomy` reflects the override in the output.
- Build clean; 20 existing config tests pass.
- `sm format --help` now shows: `--style <style> ... (values: compact, roomy)`.

### Notes

- Did not add an `analyze` subcommand path — the referenced subcommand exists only in README, not in code.
- No rule-toggle flags exist in today's CLI surface to remove. The audit of `Sources/Swiftiomatic/Subcommands/` found no rule-toggle plumbing — the `rules` map is consumed only at the Configuration/JSON layer, not as CLI flags.
- swift-format CLI contract preserved: `--style` is purely additive.
