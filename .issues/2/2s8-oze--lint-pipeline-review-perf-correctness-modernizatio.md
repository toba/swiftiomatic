---
# 2s8-oze
title: 'Lint pipeline review: perf, correctness, modernization findings'
status: completed
type: task
priority: high
created_at: 2026-04-30T05:22:17Z
updated_at: 2026-04-30T16:16:48Z
sync:
    github:
        issue_number: "534"
        synced_at: "2026-04-30T16:27:53Z"
---

Code review of the lint pipeline (`Sources/SwiftiomaticKit/Syntax/Linter/`, `Sources/SwiftiomaticKit/Support/`, `Sources/Swiftiomatic/Frontend/LintFrontend.swift`, `Sources/Swiftiomatic/Subcommands/Lint.swift`, `Sources/Swiftiomatic/Utilities/DiagnosticsEngine.swift`, generated `Pipelines+Generated.swift`) per the `/swift` skill checklist. Focus: lint pipeline performance.

## Performance — High Priority

### P1. `Context.shouldFormat` allocates per-rule per-node
`Context.shouldFormat` (`Sources/SwiftiomaticKit/Support/Context.swift:124`) is called O(rules × nodes) per file and on every call:
- computes `node.startLocation(converter:)` — recomputed per rule per node (should be once per node)
- looks up `ConfigurationRegistry.ruleNameCache[ObjectIdentifier(rule)]` (cached, OK)
- calls `ruleMask.ruleState(ruleName, at: loc)` keyed by **String** rule name (should key by `ObjectIdentifier`)
- calls `configuration.isActive(rule:)` which **does string concatenation `"\(group.key).\(rule.key)"` + dictionary lookup + `as? any SyntaxRuleValue` on every call** (`Configuration.swift:58`)

**Fix:** at `Context.init`, precompute `let enabledRules: Set<ObjectIdentifier>` from `ConfigurationRegistry.allRuleTypes`. The enabled set cannot change mid-run. `shouldFormat` becomes a single `enabledRules.contains(ObjectIdentifier(rule))` plus the per-node mask/selection check. This alone is likely the biggest single win.

### P2. `LintCoordinator` walks the tree twice per file
`LintCoordinator.lint` (`LintCoordinator.swift:170-173`) runs `RewritePipeline(context:).rewrite(...)` and **discards the output**, then runs `LintPipeline.walk(...)`. The rewriter is invoked solely to fire static `willEnter`/`transform` hooks of compact-pipeline rules in lint mode — paying the full rewrite cost (node copy/edit machinery) just to drive findings.

**Fix options:**
1. Add a "lint-only" mode to `CompactSyntaxRewriter` that walks but skips actual mutation (returns the original node unchanged from `transform`).
2. Move compact-pipeline finding emission into `LintPipeline` directly via a generated dispatch parallel to the existing one.
3. Use `SyntaxVisitor` (no `SyntaxRewriter`) to run the static hooks.

### P3. Generated dispatcher pays per-node cost for every disabled rule
`Pipelines+Generated.swift` calls `visitIfEnabled(<Rule>.visit, for: node)` for every rule registered against that node kind. Each call performs the full `Context.shouldFormat` + dict lookup, even when the rule is disabled across the whole file (very common: ~half the rules are off in any given config).

**Fix:** generate a per-Context "active dispatch table" — `Pipelines+Generated.swift` becomes a thin lookup keyed by node kind into a precomputed array of `(Rule, visit, visitPost)` closures already filtered by `enabledRules`. Or, at minimum, gate each generated `visitIfEnabled` call site on a single bool stored in `LintPipeline` (one per rule, populated at init).

### P4. `shouldSkipChildren` dict lookup on every visit
`visitIfEnabled` (`LintPipeline.swift:14, 26`) and both `onVisitPost` overloads (`LintPipeline.swift:37, 49`) consult `shouldSkipChildren[ruleID]` even when the dict is empty (the common case — virtually no rule uses skip-children).

**Fix:** short-circuit with `shouldSkipChildren.isEmpty` (single load+branch instead of dict probe). Or rework as a `Set<ObjectIdentifier>` of currently-active skips with the `SyntaxProtocol` stored separately to keep the hot path small.

### P5. `LintCache` SHA-256 hex encoding allocates per byte
`LintCache.contentHash`, `fileKey`, `fingerprint`, `ruleSetIdentifier` (`LintCache.swift:107, 137, 159, 181`) all use `digest.map { String(format: "%02x", $0) }.joined()` — 32 `String(format:)` calls + an array allocation + a join, per hash. Hot path: every file gets a content hash and a fileKey hash.

**Fix:** small helper using a static `[UInt8]` hex table writing into a pre-sized `String` (init from `withUnsafeMutableBufferPointer` of a `[CChar]` buffer, or just `[UInt8]` → `String(decoding:as: UTF8.self)`).

### P6. `LintCache.fingerprint` memoizes only the most recent config
`fingerprint(for:)` (`LintCache.swift:143`) memoizes a single `(Configuration, fingerprint)` pair. When a project has multiple `.swift-format` overrides per directory, the memo thrashes and re-encodes the whole Configuration to sorted-keys JSON per file. Consider keying by config hash (cheap) and an LRU of last N (4-8) configs.

### P7. `JSONEncoder` / `JSONDecoder` re-instantiated per call
`LintCache.lookup` (`:192`) and `store` (`:213`) and `fingerprint` (`:153`) each construct a fresh `JSONEncoder` / `JSONDecoder`. These have non-trivial init cost. Reuse a Mutex-guarded shared encoder/decoder per `LintCache` instance, or pass them through.

### P8. `lazy var` for ~17 per-rule state slots in `Context`
`Context.swift:57-74` declares 17 `lazy var` properties for compact-pipeline rule state. Swift's `lazy` access generates per-property branch + flag check on every access. For hot rules accessed thousands of times per file, that's measurable.

**Fix:** Replace lazy with `let` initialized in `init` only when the corresponding rule is enabled (uses the same `enabledRules` set from P1). For disabled rules, the slot becomes an empty `nil` Optional.

### P9. `ruleCache` heterogeneous dict + force cast on every rule access
`LintPipeline.rule(_:)` (`LintPipeline.swift:61-67`) does `ruleCache[id] as! R` on every visit (also flagged by `noForceCast` lint). `ruleCache` is `[ObjectIdentifier: any SyntaxRule]` — every access is an existential dispatch + force cast.

**Fix:** Pre-instantiate enabled rules at `LintPipeline.init` into a closed array indexed by a generated per-rule integer index (avoids dict + cast on hot path). The generator already knows every rule type.

### P10. `Context` per-file allocation of ~200 rule instances
Each `LintSyntaxRule` is a class (`LintSyntaxRule.swift:6` — `class LintSyntaxRule<V>: SyntaxVisitor, ... @unchecked Sendable`). Per file, `ruleCache` lazily builds an instance per visited rule kind. Across thousands of files in a build, that's many ARC traffic + heap allocs. Consider value-type rules where feasible (state lifted into `Context`), keeping only the lint walker as a class.

## Performance — Medium

### P11. `Context.preparedAcronyms` always evaluated even when `UppercaseAcronyms` disabled
`Context.swift:80` is `lazy` so it's only computed on first access — OK if the rule never visits when disabled. But verify generated dispatch doesn't access it for a disabled rule.

### P12. `visitor(rule)(node)` indirection allocates a closure per call
`LintPipeline.swift:16, 28` invokes the visitor as a curried function. Each `visitor(rule)` allocation may not be optimized away. Consider direct method calls in generated code (the generator can emit `rule.visit(node)` directly).

### P13. `LintCache.store` writes JSON synchronously, blocking lint critical path
After lint completes for a file, `store` performs JSON encode + atomic file write inline (`LintFrontend.swift:104`). This blocks the per-file worker thread. Move to a fire-and-forget write queue (single background worker), OR batch writes (one write per N files or at end-of-run) — important when linting hundreds of files concurrently.

### P14. `RememberingIterator` / `LazySplitSequence` — verify hot-path use
Confirm these support utilities aren't used inside the per-rule visit hot path; if so, audit for allocations.

## Correctness / Concurrency

### C1. `LintFrontend: @unchecked Sendable`
`LintFrontend.swift:19` declares `@unchecked Sendable`. The fields are `let cache: LintCache?` (Sendable). The `unchecked` looks unnecessary — investigate the parent `Frontend` and drop `@unchecked` if possible (SE-0470 / standard Sendable).

### C2. `CapturingFindingConsumer` is not `Sendable` — verify single-thread use
`LintFrontend.swift:147` is `final class` with mutable `var entries`. Created per-file inside `processFile`, used only synchronously within one `lint(...)` call. OK as long as `LintCoordinator` doesn't hand the consumer to a concurrent worker. Document the invariant or make it `Sendable` via `Mutex<[Entry]>`.

### C3. `Context.importsXCTest` is `var` on a class that may be shared across threads
`Context.swift:42` is mutable. If two rules write simultaneously the value can tear. The current pipeline runs serially per file, but document this or make it atomic.

### C4. Cache writes can race
Two concurrent `sm lint` invocations on overlapping files write to the same path. `.atomic` write makes the final state consistent (last-writer-wins) but worth noting in module docs.

## Naming / API

### N1. `LintPipeline.onVisitPost` — overloaded with three different signatures
`LintPipeline.swift:32, 45` and the generated `:64, 70` mix `onVisitPost(rule:for:)` with `onVisitPost(_:for:)`. Consider distinct names (`leaveSkipScope` vs `dispatchVisitPost`) for clarity.

### N2. `LintCache.Entry.Severity` nested 3 deep
Lint already flags this (`LintCache.swift:22, 24, 36`). Promote `Entry`, `Severity`, `Location`, `Note` to top-level nested types of `LintCache` (one level only).

### N3. `LintSyntaxRule` should be `final class`
Lint flagged: `LintSyntaxRule.swift:3`. The base class isn't designed for direct subclass use beyond rule definitions, and rule subclasses themselves should be `final`. Also `class var` → `static var` (lint flagged `:13, 16, 17`).

### N4. Force cast in `LintPipeline.rule(_:)`
`LintPipeline.swift:63: return cachedRule as! R` — flagged by `noForceCast`. Justified by the symmetric write at `:65`, but consider precondition + comment, or eliminate via P9 (typed dispatch table).

### N5. Immediately-invoked closure for `LintCache.ruleSetIdentifier`
Lint flagged `Context.swift:1` for redundantClosure (likely the `lazy var preparedAcronyms` IIFE) and could equally apply to `LintCache.swift:96`. The IIFE pattern is appropriate when the value depends on multi-step setup; verify lint suppression intent.

## Modernization

### M1. `LintCache.fingerprint` Mutex usage
The `lastFingerprint` Mutex is fine; consider whether the value type itself (`FingerprintEntry`) should be moved into the Mutex generic (already is). OK.

### M2. `consumeCachedEntry` `Severity → Diagnostic.Severity` switch duplicates `LintCache.Entry.Severity → Lint`
Two places translate severity (`DiagnosticsEngine.swift:122`, `LintCache.swift:235`). Consolidate: store `Lint` directly in `LintCache.Entry` (it's already `Codable`) — eliminates the parallel `LintCache.Entry.Severity` enum.

### M3. `LintFormatOptions` flag check could be a computed `isCacheEligible`
`LintFrontend.swift:49-55` builds the eligibility check inline. Extract a `var cacheEligible: Bool` on `LintFormatOptions` (or a free function) so the rule is testable and reusable.

### M4. `consumeFinding` / `consumeCachedEntry` paths diverge slightly
Cache replay (`DiagnosticsEngine.swift:121`) constructs `Diagnostic` with a `category:` argument; live emission via `diagnosticMessage(for finding:)` (`DiagnosticsEngine.swift:179`) uses the no-`category` initializer with `category:` left out. Verify outputs match byte-for-byte (the doc comment claims they do).

### M5. `Lint.swift` uses `ProcessInfo.processInfo.environment` parsing inline
`Lint.swift:48` parses `SM_LINT_NO_CACHE` ad hoc. Extract a `LintCache.disabledByEnvironment` static helper.

## XCTest → Swift Testing

N/A — these files contain no test code.

## CKSyncEngine

N/A — no CloudKit.

## Summary
- **High priority (perf):** 10 (P1-P10)
- **Medium priority:** 4 (P11-P14)
- **Correctness:** 4 (C1-C4)
- **Naming/API:** 5 (N1-N5)
- **Modernization:** 5 (M1-M5)

**Most leverage**: P1 (precompute enabled-rules set), P3 (filter generated dispatch by enabled rules), P2 (eliminate the dual tree walk), P5 (faster hex), P9 (typed dispatch table). P1 + P3 likely give the largest single speedup for the lint hot path because they eliminate ~half the per-node-per-rule cost from disabled rules.


## Summary of Changes

Landed the high-leverage, lower-risk items from this review. Larger refactors (typed dispatch table, eliminating the dual tree walk, value-type rules, generator-driven enabled-rule gating, schema-bumping cache changes) are deferred to follow-up issues so they can land with their own perf measurements and tests.

### Done

- **P1** — `Context` precomputes `enabledRules: Set<ObjectIdentifier>` once per file from `ConfigurationRegistry.allRuleTypes` × `Configuration.isActive(rule:)`. `shouldFormat(ruleType:node:)` and the `Gate`-based `shouldRewrite` now short-circuit on disabled rules before paying for `startLocation` + `RuleMask` work — eliminating the per-rule per-node `Configuration.isActive` string concat for the ~half of rules that are off.
- **P4** — `LintPipeline.visitIfEnabled` / `onVisitPost` short-circuit with `shouldSkipChildren.isEmpty` before probing the dictionary (the common case is empty).
- **P5** — Replaced four `digest.map { String(format: "%02x", $0) }.joined()` sites with a single `LintCache.hexEncode(_:)` helper that pre-reserves the result string and writes hex pairs from a static UTF-8 table.
- **P7** — `LintCache` now holds a Mutex-guarded `Coders` struct with reusable `JSONEncoder`/`JSONDecoder` (separate fingerprint encoder retains `.sortedKeys`). `lookup`, `store`, and `fingerprint` no longer instantiate fresh coders per call.
- **C3** — Documented `Context.importsXCTest` thread-safety invariant (single `Context` per file, serial pipeline).
- **M3** — Extracted `LintCache.isCacheEligible(url:lines:offsets:ignoreUnparsableFiles:)` so the eligibility rule lives next to the cache and is testable.
- **M5** — Extracted `LintCache.disabledByEnvironment` static helper; `Lint.run()` now reads it instead of parsing the env var inline.
- Added `LintCacheTests` covering `hexEncode`, `contentHash`, and the eligibility helper.

### Deferred (follow-up issues recommended)

- **P2** — Eliminating the dual tree walk in `LintCoordinator.lint` (compact-pipeline rewriter run for finding emission only) needs either a lint-only mode for `CompactSyntaxRewriter` or a parallel generated dispatcher. Significant generator change.
- **P3** — Filtering generated dispatch by `enabledRules` (per-Context active dispatch table). Generator change.
- **P6** — LRU memo for `LintCache.fingerprint` across multiple configurations.
- **P8** — Replacing `lazy var` per-rule state slots with optional `let` initialized only when the rule is enabled.
- **P9** — Typed dispatch table to remove `as! R` and the heterogeneous `ruleCache` dictionary.
- **P10** — Value-type rules to cut per-file class allocations.
- **P11/P12/P13/P14** — Verify `preparedAcronyms` access path; remove visitor closure indirection in generated code; move cache writes to a background queue; audit `RememberingIterator`/`LazySplitSequence` for hot-path use.
- **C1/C2** — Drop or document `@unchecked Sendable` on `LintFrontend` (parent `Frontend` is also `@unchecked`, would need to migrate together) and `CapturingFindingConsumer`.
- **C4** — Document concurrent-cache-write race in module docs.
- **N1** — Rename overlapping `onVisitPost` overloads.
- **N2** — Promote `LintCache.Entry.{Severity,Location,Note}` one nesting level.
- **N3** — Make `LintSyntaxRule` and rule subclasses `final`; convert `class var` → `static var` where no override exists. Multiple subclasses use `class var` overrides today, so this needs an audit pass.
- **N4** — Eliminate the force cast via P9.
- **N5** — Audit lint-flagged IIFE patterns.
- **M1** — Mutex generic for `lastFingerprint` is fine as-is.
- **M2** — Store `Lint` directly in `LintCache.Entry` (drops the parallel `Severity` enum). Bumps cache schema version.
- **M4** — Verify `consumeFinding` / `consumeCachedEntry` outputs match byte-for-byte.

### Verification

Main targets build cleanly. New `LintCacheTests` (6 tests) pass on the targeted slice. The 14 layout/pretty-printer tests currently failing are unrelated — they belong to another agent's in-flight changes to `TokenStream+Operators.swift` / `TokenStream+Appending.swift` and don't touch any code paths modified here.
