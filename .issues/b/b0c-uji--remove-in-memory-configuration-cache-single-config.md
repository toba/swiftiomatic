---
# b0c-uji
title: Remove in-memory Configuration cache (single-config simplification)
status: completed
type: task
priority: normal
created_at: 2026-02-28T22:48:11Z
updated_at: 2026-02-28T22:49:54Z
sync:
    github:
        issue_number: "30"
        synced_at: "2026-03-01T01:01:34Z"
---

With the removal of nested/merged config file support, the in-memory `cachedConfigurationsByIdentifier` cache in `Configuration+Cache.swift` is no longer valuable — there's only ever one config, so the dictionary lookup is pointless overhead.

## What to remove

- [x] `cachedConfigurationsByIdentifier` static property
- [x] `getCached(forIdentifier:)` 
- [x] `setCached(forIdentifier:)`
- [x] `resetCache()`
- [x] `computedCacheDescription` stored property — removed from Configuration.swift and description
- [x] Call sites in `Configuration.swift` — removed cache lookup and setCached call

## What to keep

- `cacheDescription` (SHA-256 fingerprint) — powers `LinterCache` for on-disk incremental caching
- `cacheURL` — resolves the on-disk cache directory
- `withPrecomputedCacheDescription()` — avoids repeated hashing

## Notes

The on-disk `LinterCache` is still valuable for skipping unchanged files between runs. Only the in-memory per-identifier cache is dead weight.


## Summary of Changes

Removed the in-memory `cachedConfigurationsByIdentifier` cache from `Configuration+Cache.swift` and all related code:
- Deleted `cachedConfigurationsByIdentifier`, `getCached`, `setCached`, `resetCache`, `withPrecomputedCacheDescription`
- Removed `computedCacheDescription` stored property from `Configuration`
- Removed cache lookup/store in the convenience initializer
- Removed `import Synchronization` (no longer needed)
- Kept on-disk `cacheDescription` and `cacheURL` intact for `LinterCache`
