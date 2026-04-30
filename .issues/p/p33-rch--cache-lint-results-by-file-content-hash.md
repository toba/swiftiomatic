---
# p33-rch
title: Cache lint results by file content hash
status: completed
type: feature
priority: high
created_at: 2026-04-30T04:15:35Z
updated_at: 2026-04-30T04:39:24Z
sync:
    github:
        issue_number: "526"
        synced_at: "2026-04-30T05:51:02Z"
---

## Problem

`sm lint --parallel --recursive Sources/SwiftiomaticKit` takes ~7s wall / ~46s CPU on every invocation, even when nothing changed. This dominates Xcode build wall-time when the prebuild lint plugin is attached, and is the root cause of why the plugin had to be removed from `SwiftiomaticKit` in the working tree.

Per-file cost is ~22ms × 305 files. Startup is negligible (~12ms). So the work is genuinely 'lint every file every time'.

## Proposal

Cache lint findings keyed by file content hash (and a 'lint engine fingerprint' that invalidates the whole cache when rules change).

- Cache location: `.build/sm-lint-cache/` (or `~/Library/Caches/sm/<project-hash>/`).
- Key per file: SHA256 of file contents + engine fingerprint.
- Value: list of findings (or empty for clean).
- On lint: hash file → if cache hit, replay cached findings; else lint, store result.
- Engine fingerprint: hash of rule list + rule version + configuration. Bump on any rule change to force re-lint.

## Expected impact

- No-change run: ~0.05s (just hash 305 files).
- 1–2 changed files: ~0.2s.
- Cache miss after rule change: same as today (~7s) — one-time cost.

This unblocks re-attaching the prebuild lint plugin to `SwiftiomaticKit` (currently removed for build-speed reasons — see wpg-h5c).

## Open questions

- Where to put the cache (per-project `.build` vs user cache dir).
- Should the cache be shared between `sm format` and `sm lint`?
- How to invalidate when configuration changes mid-session.
- Whether to cache fixits/format rewrites too (probably out of scope for v1).

## References

- wpg-h5c — Speed up swift package test wall-time: prebuild lint plugin dominates



## Summary of Changes

Added a content-addressed lint cache that turns no-change `sm lint` runs into hash-and-replay.

**New:** `Sources/SwiftiomaticKit/Support/LintCache.swift` — `LintCache.Record` (Codable), `LintCache.Entry` (flattened finding primitives, since `Finding.category` is a non-Codable protocol), SHA-256 content + configuration fingerprint, on-disk layout `.build/sm-lint-cache/<fingerprint[..16]>/<key>.json`. Atomic write-then-rename. Memoizes the per-`Configuration` fingerprint via `Mutex` so the typical single-config tree pays the JSON-encode + hash exactly once per run.

**Engine fingerprint** = SHA-256 of (sorted `ConfigurationRegistry.allRuleTypes` reflected names + JSON-encoded `Configuration` with sortedKeys + cache schema version). Adding/removing/renaming a rule (binary rebuild) or changing config orphans every prior subtree. `swift package clean` clears them.

**Wired into:** `Sources/Swiftiomatic/Frontend/LintFrontend.swift` — looks up by `(absolutePath, contentHash, fingerprint)` before constructing `LintCoordinator`. On hit, replays cached entries via new `DiagnosticsEngine.consumeCachedEntry(_:)` (same `emit(Diagnostic)` path → byte-identical stderr + identical `hasErrors`/`hasWarnings` accounting). On miss, captures findings via `CapturingFindingConsumer` while forwarding them, then persists. Bypassed for `--lines`/`--offsets`, stdin, `--ignoreUnparsableFiles`, and any file the parser couldn't parse (avoids poisoning the cache with a record that suppresses real findings).

**Flag:** `--no-cache` on `sm lint` (also `SM_LINT_NO_CACHE=1` env var).

**Plugin re-attached:** `Package.swift` — `SwiftiomaticBuildToolPlugin` is back on `SwiftiomaticKit.plugins` (after `GenerateCode`). The cache makes warm prebuild runs cheap enough that this no longer regresses wpg-h5c.

## Measured impact

On `Sources/SwiftiomaticKit/` (305 files, release build of `sm`):

| Run | Wall | CPU |
|---|---|---|
| Cold (cache cleared) | 7.33s | 45.25s |
| Warm (cache hit) | **0.24s** | 1.61s |
| `--no-cache` | 6.85s | 50.36s |

~30× wall-time speedup on no-change runs. Sorted output is byte-identical between cold and warm (280 lines, diff empty).

## Out of scope (deferred)

- Caching `sm format` rewrites.
- Shared cache across `format` and `lint`.
- User-cache fallback (`~/Library/Caches/sm/...`).
- Cache size cap / eviction.
- Unit tests for `LintCache` directly (covered indirectly by warm-run output equality).
