---
# gwg-x66
title: 'sm format strips '': Sendable'' protocol conformance from struct/enum/class declarations'
status: completed
type: bug
priority: high
created_at: 2026-05-08T22:08:16Z
updated_at: 2026-05-08T22:14:33Z
sync:
    github:
        issue_number: "674"
        synced_at: "2026-05-08T22:24:57Z"
---

## Summary

Running `sm format` on Thesis files removed `Sendable` (and possibly other) protocol conformances from many declarations, breaking compilation. 53 stripping events across ~45 files in one pass.

## Examples

### Plain `Sendable`-only conformance dropped entirely

`Integrations/Zotero/Sources/API/Client.swift`:
```diff
-    struct Client: Sendable {
+    struct Client {
```

This caused downstream errors:
- `'client' of 'Sendable'-conforming struct 'Manager' has non-Sendable type 'Zotero.Client'`
- `capture of 'self' with non-Sendable type 'Zotero.Client' in a '@Sendable' closure` (in Client+collections, Client+items, Client+tags)

### `Sendable` removed from multi-conformance lists

`Integrations/CSL/Sources/Elements/Rendering/MacroElement.swift`:
```diff
-struct MacroElement: Equatable, SuppressibleParent, CSLDecodable, XMLIdentifiable, Sendable {
+struct MacroElement: Equatable, SuppressibleParent, CSLDecodable, XMLIdentifiable {
```

`Integrations/CSL/Sources/Terms/BasicTerm.swift`:
```diff
-enum BasicTerm: String, Equatable, Sendable, XMLIdentifiable {
+enum BasicTerm: String, Equatable, XMLIdentifiable {
```

`Integrations/RIS/Source/FileRow.swift`:
```diff
-    enum FileRow: Equatable, Sendable {
+    enum FileRow: Equatable {
```

### Affected file count

~45 files in a single sweep. Many of these `Sendable` conformances are load-bearing — types stored on actor-isolated/Sendable parents must themselves be `Sendable`, and removing the conformance silently turns the type non-Sendable.

## Hypothesis

Likely the redundant-protocol-conformance rule misclassifies `Sendable` as redundant. `Sendable` is *never* redundant in source — even when a type would synthesize Sendable conformance (e.g., a struct of all-Sendable stored properties), explicit `: Sendable` is the public-API contract for non-`@frozen` types and the only way to surface the conformance to `public` clients across module boundaries. Stripping it changes semantics.

## Severity

High. Across the Thesis tree this single bug accounted for ~25 build errors after one `sm format` run, in files with no other intentional changes. Recovery requires manual restoration of every conformance; the diff is not auditable as "format-only" since semantic changes are mixed with whitespace.

## Suggested fix

Treat `Sendable` (and any marker / `@_marker` protocol) as never-redundant. Conservative fix: add `Sendable` to a never-strip list alongside `AnyObject`.



## Summary of Changes

Removed `DropRedundantSendable` rule entirely. The rule's premise — that non-public structs/enums always get implicit `Sendable` synthesis — only holds when *every* stored property is `Sendable`. A syntax-only AST tool can't verify that without type information, so the rule blindly stripped `Sendable` from types whose stored properties were non-Sendable (e.g., `URLSession`), turning the parent type non-Sendable and breaking compilation across ~45 files in Thesis.

Changes:
- Deleted `Sources/SwiftiomaticKit/Rules/Redundancies/DropRedundantSendable.swift`
- Deleted `Tests/SwiftiomaticTests/Rules/DropRedundantSendableTests.swift`
- Removed dispatch from `Sources/SwiftiomaticKit/Syntax/Rewriter/RewritePipeline.swift` (both struct and enum apply sites)
- Removed entry from `Sources/SwiftiomaticKit/Generated/ConfigurationRegistry+Generated.swift` (build plugin regenerates this)

Verified with `swift_diagnostics`: build succeeds.
