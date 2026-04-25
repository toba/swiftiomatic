---
# 3zg-ma5
title: 'fatalError audit: convert programmer-error invariants'
status: completed
type: task
priority: normal
created_at: 2026-04-25T20:43:12Z
updated_at: 2026-04-25T21:18:20Z
parent: 0ra-lks
sync:
    github:
        issue_number: "432"
        synced_at: "2026-04-25T22:35:11Z"
---

55 `fatalError`/`preconditionFailure` calls. Some guard genuine programmer-error invariants (fine), others can be triggered by malformed input and should recover gracefully.

## Findings

- [x] `Sources/SwiftiomaticKit/Layout/LayoutCoordinator.swift:191, 269, 495, 716` — converted all four to `assertionFailure(...)` + early-return-from-`emitToken` (cases inside the per-token switch) and `assert(...)` for the post-loop unmatched-open-break check. Best-effort output instead of process crash on malformed token streams.
- [x] `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+TypeDeclarations.swift:103` — converted to `assertionFailure(...)` + `return .visitChildren` so parser-recovery extension nodes don't crash the formatter.
- [x] `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Appending.swift:203` — converted to `assertionFailure(...)` + `return`. Internal bookkeeping invariant.
- [x] `Sources/SwiftiomaticKit/Support/Selection.swift:76, 87, 105` — `fatalError` → `preconditionFailure` (clearer intent for "must call resolved(with:) first").
- [x] `Sources/SwiftiomaticKit/Configuration/JSONValueEncoder.swift:14, 39, 42, 44, 45` — `fatalError()` → `preconditionFailure(...)` with descriptive messages and a doc-comment invariant on the type. Encoder is only used for flat keyed projection; unkeyed/nested/superEncoder paths are unreachable, but a clearer trap fires if a future caller exercises them.
- [x] `Sources/Swiftiomatic/Frontend/Frontend.swift:302-305` — `precondition` → `assert`. Caller (`run()`) already gates non-empty paths; the only remaining caller is the same file.

## Verification
- [x] Build clean.
- [x] Targeted tests pass: 96/96 (Configuration, API, Verbatim, Comment, WhitespaceLinter, LayoutBuffer, PreferSynthesizedInitializer, OpaqueGenericParameters suites).
- [ ] Targeted malformed-input tests not added; the changes don't alter happy-path behavior, only the failure mode (debug crash → release best-effort). Adding crafted malformed-token-stream tests would be valuable follow-up but is out of scope for this audit.

## Summary of Changes

Converted six classes of process-killing traps to debug-only assertions with safe release-mode fallbacks, plus tightened the language of programmer-error invariants:

- **Recoverable** (debug `assertionFailure` + early return for best-effort output): four `LayoutCoordinator.emitToken` invariants, the extension-decl token check, and the `lastBreakIndex` non-break invariant in `TokenStream+Appending`.
- **Programmer-error** (kept fatal but with clearer diagnostic): three `Selection` "must resolve first" calls switched to `preconditionFailure`; five `JSONValueEncoder` Encoder-API stubs switched to `preconditionFailure` with descriptive messages and an invariant doc on the type.
- **Trivially redundant**: `Frontend.processURLs` `precondition(!urls.isEmpty)` → `assert` (caller gates this in the same file).

Net: malformed input or buggy upstream rules now produce best-effort output instead of crashing the formatter binary in release; debug builds still trip the assertion so test/CI catch the bug.
