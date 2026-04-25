---
# 0ra-lks
title: Pre-release Swift code review cleanup
status: completed
type: epic
priority: high
created_at: 2026-04-25T20:39:30Z
updated_at: 2026-04-25T22:34:12Z
sync:
    github:
        issue_number: "417"
        synced_at: "2026-04-25T22:35:08Z"
---

Pre-release cleanup pass over `Sources/` (305 files, fork of apple/swift-format). Findings from a `/swift` code review focused on best practices, performance, and Swift 6.x modernization.

Sub-issues group findings by category. File:line references and concrete fixes live in each child.

## Categories

### Performance
- Configuration equality: O(n) encoder allocation
- Layout output: hot-path string allocations (Verbatim, LayoutBuffer, Comment, WhitespaceLinter)
- Quadratic lookups in rules (PreferSynthesizedInitializer, OpaqueGenericParameters)
- Frontend parallelism: DispatchQueue → TaskGroup, stream files instead of materializing
- Misc small perf nits (cached RefResolver, currentIndentation cache, count-1 indexing, multi-pass over data)

### Swift 6.x modernization
- Remove unnecessary `nonisolated(unsafe)` annotations
- Drop `@unchecked Sendable` from frontend classes
- Typed throws on JSON5Scanner and friends
- Replace `[String: any Sendable]` storage in Configuration

### Code duplication
- Consolidate duplicated rule visit overloads (TripleSlashDocComments, SimplifyGenericConstraints, SortDeclarations)
- Extract modifier-check + config-reading helpers
- Consolidate TokenStream+Helpers overloads
- Extract JSON-modify utility and range-parse helper

### Architecture / correctness
- ConfigurationLoader: struct → final class
- Audit visitor-state lifecycle (PreferFinalClasses, RedundantSelf)
- fatalError audit (convert programmer-error invariants)
- PreferSynthesizedInitializer: convert lint to rewrite

### Cleanup
- Naming nits (`case no` → `case off`, etc.)
- Dead code (commented ConfigurationItem, single-reference helpers)
- Findings emission anchors and notes
- Doc-rule defaults audit

Each sub-issue is small and independently actionable.


## Summary of Changes

All 21 child issues resolved (19 completed, 2 scrapped). Final test suite: 2795 passed, 0 failed.

### Completed (19)

Performance:
- 4sp-t4r — Configuration equality: cached encoder allocation eliminated
- ibj-51h — Layout output: hot-path string allocations removed
- ken-g7x — Quadratic lookups in PreferSynthesizedInitializer / OpaqueGenericParameters
- skr-zyu — Frontend parallelism: DispatchQueue → TaskGroup, file streaming
- y5m-pr3 — Misc small perf nits (slice allocations, JSONPointer single-pass, lock scope)

Swift 6.x modernization:
- 4hc-acl — Removed unnecessary nonisolated(unsafe) annotations
- jgp-v81 — Dropped @unchecked Sendable from Frontend classes
- ihk-n7y — Typed throws on JSON5Scanner and configuration loaders
- ali-5f1 — Replaced [String: any Sendable] silent-fallback with type-mismatch precondition + recursive JSONValueBuilder

Code duplication:
- 91t-bu9 — Consolidated duplicated rule visit overloads
- c0v-u8y — Extracted modifier-check and config-reading helpers
- 3mr-upn — Consolidated TokenStream+Helpers overloads (areBracesCompletelyEmpty, parameter clauses)
- 0sj-ok2 — Extracted codingClosures, qualifiedKeyParts, parseIntPair helpers

Architecture / correctness:
- k12-apv — ConfigurationLoader struct → final class with internal Mutex
- e4f-izo — Audited visitor-state lifecycle
- 3zg-ma5 — fatalError audit (programmer-error invariants)

Cleanup:
- grc-8u0 — Naming nits (doesThrow → hasThrow, isUsed → wasUsed)
- xah-el5 — Dead code removal (ConfigurationItem) and schemaURL relocation
- ngs-wnq — Findings emission improvements investigated

### Scrapped (2)

- 5y3-zcd — PreferSynthesizedInitializer rewrite conversion: deferred to its own focused issue (substantial scope: ~495 lines of test rework + careful trivia preservation)
- 81i-nlr — Doc-rule defaults audit: scrapped earlier in the pass
