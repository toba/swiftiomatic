---
# bzd-9lq
title: Add PairAcquireWithDefer lint rule (acquire-without-paired-defer-release)
status: completed
type: feature
priority: normal
created_at: 2026-06-03T03:15:42Z
updated_at: 2026-06-03T03:27:04Z
sync:
    github:
        issue_number: "717"
        synced_at: "2026-06-03T03:27:49Z"
---

**Source:** Majid's defer essay covered in iOS Code Review Issue #79 — https://ioscodereview.com/issues/issue-79-defer-done-right-instruments-is-back-and-wwdc-is-one-week-away/

**Pattern**

When code acquires a resource or sets state that must be reversed (lock, transaction, drawing context, scoped resource, edit batch, transient flag), the cleanup should be written as `defer { release() }` *immediately* after the acquire — before any branching. Without it, a future `return` / `throw` / `break` added downstream silently skips the release. The article calls this Swift's most underused safety feature.

**Example**

```swift
// Bad — early return skips endEditing
func reload() {
    textStorage.beginEditing()
    guard let items = source.items else { return }
    apply(items)
    textStorage.endEditing()
}

// Good
func reload() {
    textStorage.beginEditing()
    defer { textStorage.endEditing() }
    guard let items = source.items else { return }
    apply(items)
}
```

**Proposed rule**

- Name: `PairAcquireWithDefer` (Rules/ControlFlow/ or Rules/Memory/)
- Mode: lint-only (no rewrite — release call site/args aren't always inferable, and an RAII wrapper may be preferable)
- Default: warn

**Detection (SwiftSyntax, no type info)**

1. Walk function/closure bodies. For each `FunctionCallExprSyntax` whose called member matches a configured acquire name, check whether the enclosing scope contains a subsequent `DeferStmtSyntax` whose body contains a call to the paired release name on a syntactically matching base expression.
2. Only flag when the enclosing scope has at least one early exit point (`return` / `throw` / `break` / `continue`) after the acquire — a straight-line function that ends with the release is benign.
3. Skip when an RAII wrapper exists for the same base (`.withLock`, `.withSpan`, `withTaskGroup`, etc.) — those are preferred and likely a separate rule (`PreferRAIIWrapper`).

**Pair catalog (initial, configurable)**

| Acquire                                  | Release                                  |
|------------------------------------------|------------------------------------------|
| `lock()`                                 | `unlock()`                               |
| `objc_sync_enter(_:)`                    | `objc_sync_exit(_:)`                     |
| `beginUpdates()`                         | `endUpdates()`                           |
| `beginEditing()`                         | `endEditing()`                           |
| `CGContext.saveGState()`                 | `CGContext.restoreGState()`              |
| `CATransaction.begin()`                  | `CATransaction.commit()`                 |
| `NSAnimationContext.beginGrouping()`     | `NSAnimationContext.endGrouping()`       |
| `startAccessingSecurityScopedResource()` | `stopAccessingSecurityScopedResource()` |
| `os_signpost(.begin, ...)`               | `os_signpost(.end, ...)`                 |

Catalog should be extensible via configuration (`pairs: [{ acquire: "...", release: "..." }]`).

**Caveats**

- Syntax-only matching → name collisions cause false positives. Mitigations: match on full member-access chain when possible, and keep the default catalog conservative (well-known Apple framework names).
- Don't flag when cleanup legitimately belongs in only one branch (rare); a `// swiftiomatic:disable PairAcquireWithDefer` comment should suppress.

**Out of scope**

- Auto-inserting the `defer` (release arity/args can vary — `os_signpost` takes labels, `objc_sync_exit` takes the object). Lint-only for now; revisit auto-fix after the rule earns its keep.

**Acceptance**

- Rule with configurable pair catalog
- Test fixtures: clean case, missing-defer case, early-return case, RAII-wrapper-available case, disable-comment case
- Default `warn` in shipped config
- README rule table updated



## Summary of Changes

- Added `PairAcquireWithDefer` lint rule (group `unsafety`) under `Sources/SwiftiomaticKit/Rules/Unsafety/PairAcquireWithDefer.swift`.
- **Lint-only, no rewrite.** The release call's arguments (`objc_sync_exit(obj)`, etc.) cannot always be inferred from the acquire site, and the right fix is sometimes an RAII wrapper rather than a `defer`.
- **Detection:** for each acquire call in a code block, walk the remainder of the same scope and flag if (a) no `defer { release() }` for the paired name appears below it AND (b) an early-exit (`return` / `throw` / `break` / `continue` / unmarked `try`) appears below it. Nested function and closure bodies are skipped — their exits leave inner scopes, not the acquire's scope.
- **Configurable catalog** via `PairAcquireWithDeferConfiguration.pairs` (`[AcquireReleasePair]`). User configuration replaces the catalog wholesale. Default catalog covers: `lock`/`unlock`, `objc_sync_enter`/`objc_sync_exit`, `beginUpdates`/`endUpdates`, `beginEditing`/`endEditing`, `saveGState`/`restoreGState`, `beginGrouping`/`endGrouping`, `startAccessingSecurityScopedResource`/`stopAccessingSecurityScopedResource`.
- **Default severity:** `warn`.
- **Tests:** 10 cases in `PairAcquireWithDeferTests` covering clean straight-line code, missing-defer with early return, missing-defer with `throw`, properly-paired defer, free-function (`objc_sync_enter`), nested-closure exit (does not count), acquire inside a closure (still flagged), defer above the acquire (does not pair), and unknown method names (not flagged).
- Generator run; rule registered in `Pipelines+Generated.swift` etc.
- Full suite: 3436 passed / 0 failed.

## Deferred from this issue

- `os_signpost(.begin, ...)` / `os_signpost(.end, ...)` pairing — same call name on both sides, distinguished by an argument, requires argument-content analysis that doesn't fit the simple catalog model.
- `CATransaction.begin` / `CATransaction.commit` — `begin` is too generic; would need base-type matching.
- Detection of an existing RAII wrapper (`withLock`, custom `with…`) for the same base — slated for a separate `PreferRAIIWrapper` rule per the issue body.
