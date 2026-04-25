---
# ken-g7x
title: Quadratic lookups in PreferSynthesizedInitializer / OpaqueGenericParameters
status: completed
type: task
priority: normal
created_at: 2026-04-25T20:41:34Z
updated_at: 2026-04-25T21:13:55Z
parent: 0ra-lks
sync:
    github:
        issue_number: "437"
        synced_at: "2026-04-25T22:35:12Z"
---

Two rules contained O(n²) lookups that show up on files with many declarations.

## Findings

- [x] `Sources/SwiftiomaticKit/Rules/Declarations/PreferSynthesizedInitializer.swift` — replaced `firstIndex(of:)` + `remove(at:)` per variable with a `[String: Int]` count-multiset built once, decremented per variable. O(n²) → O(n).
- [x] `Sources/SwiftiomaticKit/Rules/Generics/OpaqueGenericParameters.swift` — replaced three `types.firstIndex(where: { $0.name == leftName })` calls with a single `[String: Int]` index map built once. The where-clause walk drops from O(n × requirements) to O(n + requirements).

## Verification
- [x] Build clean.
- [x] Targeted tests pass: 45/45 (PreferSynthesizedInitializer + OpaqueGenericParameters suites).

## Summary of Changes

**`PreferSynthesizedInitializer.swift`** — `areStructFieldAssignments(_:variables:)`:
Built a count-multiset (`[String: Int]`) of statement identifiers up front and decrement per variable, replacing the per-variable `firstIndex(of:)` + `remove(at:)` (each O(n)). Behavior preserved: every variable still consumes exactly one matching `self.x = x` statement, and no statements may be left over.

**`OpaqueGenericParameters.swift`** — `analyzeGenericParams(...)`:
Built `typeIndexByName: [String: Int]` once after collecting `types`, then replaced the three `types.firstIndex(where: { $0.name == leftName })` calls (one in `.conformanceRequirement`, two in `.sameTypeRequirement`) with O(1) dictionary lookups. The set of names being added doesn't grow during the where-clause walk, so the cached index map stays valid.
