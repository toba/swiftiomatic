---
# ali-5f1
title: 'Replace [String: any Sendable] storage in Configuration'
status: completed
type: task
priority: normal
created_at: 2026-04-25T20:42:40Z
updated_at: 2026-04-25T21:57:21Z
parent: 0ra-lks
sync:
    github:
        issue_number: "430"
        synced_at: "2026-04-25T22:35:11Z"
---

Configuration uses runtime type erasure with silent `as?` fallback — bugs become silent.

## Findings

- [x] `Sources/SwiftiomaticKit/Configuration/Configuration.swift:44` — `private var values: [String: any Sendable] = [:]`. Subscript performs `as? C.Value` and falls back to `defaultValue` on miss. If a stored value's type drifts from the rule's `Value`, the bug is invisible.
- [x] `Sources/SwiftiomaticKit/Configuration/JSONValueEncoder.swift:58-66` — `toJSONValue<T>` does runtime pattern matching (`case let X as Y`), then for unmatched `T` allocates a full `JSONEncoder`/`JSONDecoder` round-trip. Replace with a typed encoding path (e.g. specialize on `Codable` primitives, route the rest through `JSONValue.init(from:)`).

## Test plan
- [x] Existing config encode/decode tests pass
- [x] Type-mismatch is now detected via `preconditionFailure` in the subscript getter (no test added because the storage is private and Configurable registration cannot create a key collision through the public API; the trap fires only on programmer error in registry wiring)


## Summary of Changes

- `Configuration.swift` subscript getter now traps with a diagnostic when stored value type drifts from `C.Value` instead of silently returning the default. Set/get paths share a single key derivation.
- `JSONValueEncoder.swift` replaces the `JSONEncoder`/`JSONDecoder` round-trip with a recursive `JSONValueBuilder` that builds `JSONValue` directly. Primitives short-circuit; non-primitives encode through nested keyed/unkeyed/single-value containers.
- All 2795 tests pass.
