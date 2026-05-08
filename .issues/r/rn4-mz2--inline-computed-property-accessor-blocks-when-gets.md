---
# rn4-mz2
title: Inline computed-property accessor blocks when get/set bodies are single statements
status: completed
type: feature
priority: normal
created_at: 2026-05-08T06:48:12Z
updated_at: 2026-05-08T06:54:23Z
---

## Problem

When the inline-single-line-bodies layout rule is active, computed properties with `get`/`set` accessors whose bodies are each a single statement should be collapsed to one line, matching how single-statement function bodies are inlined.

## Example

Input:

```swift
public extension CredentialRepresentable {
    var key: String {
        get { id }
        set { id = newValue }
    }
    var token: String {
        get { id }
        set { id = newValue }
    }
    var username: String {
        get { id }
        set { id = newValue }
    }
    var password: String {
        get { secret }
        set { secret = newValue }
    }
}
```

Expected output:

```swift
public extension CredentialRepresentable {
    var key: String { get { id } set { id = newValue } }
    var token: String { get { id } set { id = newValue } }
    var username: String { get { id } set { id = newValue } }
    var password: String { get { secret } set { secret = newValue } }
}
```

## Conditions

- Only when the inline-single-line-bodies layout rule is active
- Each accessor (`get`, `set`, optionally `_modify`/`willSet`/`didSet`) has a body containing a single statement (e.g. simple assignment or expression)
- The collapsed line still fits within the configured line length

## Tasks

- [x] Add a failing test case in the layout tests (single-line bodies suite) covering the example above
- [x] Extend the inline-single-line-bodies logic to handle `AccessorBlockSyntax` with multiple single-statement accessors
- [x] Ensure the collapse only applies when each accessor body is a single statement and the resulting line fits
- [x] Verify behavior when `set` is omitted (read-only computed properties already inline; check no regression)
- [x] Verify `willSet`/`didSet` observers behave correctly under the same rule



## Summary of Changes

- Added `inlineAccessors` helper in `Sources/SwiftiomaticKit/Rules/Wrap/LayoutSingleLineBodies.swift` that collapses an `AccessorBlockSyntax` of explicit `get`/`set` (and `_modify`/`_read`) accessors onto one line when every accessor body is a single statement, no comments are present, and the inlined form fits within the configured line length.
- Wired it into the `.accessors` branch of `inlineProperty` (previously a no-op).
- Skips `willSet`/`didSet` observer accessors so the existing observer-only inlining (which preserves the outer multiline block) remains unchanged.
- Added four tests in `Tests/SwiftiomaticTests/Rules/Wrap/LayoutSingleLineBodiesTests.swift` covering the happy path, multiline accessor bodies, line-length cutoff, and multi-statement accessor (no-op).
- All 51 `SingleLineBodiesInlineTests` pass; no regressions in the wider suite caused by this change.
