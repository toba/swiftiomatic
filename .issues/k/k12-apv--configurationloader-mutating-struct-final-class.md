---
# k12-apv
title: 'ConfigurationLoader: mutating struct → final class'
status: completed
type: task
priority: low
created_at: 2026-04-25T20:43:12Z
updated_at: 2026-04-25T22:00:51Z
parent: 0ra-lks
sync:
    github:
        issue_number: "428"
        synced_at: "2026-04-25T22:35:11Z"
---

`Sources/Swiftiomatic/Frontend/ConfigurationLoader.swift:18-49` — `struct ConfigurationLoader` with `mutating func configuration(...)`. Wrapped in `Mutex<ConfigurationProvider>` and re-locked on every file. The mutating-struct dance exists only because the cache is a `var`.

## Fix

- [x] Convert to `final class ConfigurationLoader: Sendable` with internal `Mutex<[String: Configuration]>` cache
- [x] Drop the outer `Mutex<ConfigurationProvider>` indirection in `Frontend.swift:198, 273-277, 333-338` (or simplify it now that the loader can be shared)

## Test plan
- [x] Existing `ConfigurationLoader` and frontend tests pass
- [x] Multi-file `sm format` run still respects per-directory config (existing tests cover this)


## Summary of Changes

- `ConfigurationLoader` is now `final class: Sendable` with an internal `Mutex<[String: Configuration]>` cache. Methods are no longer `mutating`.
- `Frontend.ConfigurationProvider` becomes `Sendable` (its loader is now a reference); `provide(...)` is no longer `mutating`.
- `Frontend.configurationProvider` drops the outer `Mutex<ConfigurationProvider>` wrapper. Both call sites (`processStandardInput`, `openAndPrepareFile`) now invoke `provide(...)` directly.
- All 2795 tests pass.
