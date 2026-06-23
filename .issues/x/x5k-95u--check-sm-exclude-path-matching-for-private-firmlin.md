---
# x5k-95u
title: Check sm exclude-path matching for /private firmlink mismatch
status: completed
type: bug
priority: normal
created_at: 2026-06-23T16:15:45Z
updated_at: 2026-06-23T16:34:31Z
sync:
    github:
        issue_number: "741"
        synced_at: "2026-06-23T16:36:29Z"
---

## Background

Upstream SwiftLint commit `105980be` ("Honor excluded paths for projects under /private-symlinked directories", #6783) fixes a silent mis-exclusion bug:

On macOS, path standardization (`String.url()`) strips a leading `/private` from firmlinked paths (`/tmp`, `/var`). But the directory enumerator yields paths that **keep** the `/private` prefix. So exclusion matchers/prefixes (derived from standardized URLs) never matched the enumerated candidates, and excluded files (e.g. generated code) got linted anyway — in CI workspaces and `mktemp` directories.

Their fix: compare each candidate against the exclude prefix both **with and without** the `/private` prefix, using string ops only (avoiding a per-file `stat` that standardizing every candidate would incur).

## Risk to Swiftiomatic

If `sm`'s recursive directory walk + exclude-path matching standardizes the exclude patterns but enumerates raw `/private/...` paths, we have the same bug: `--exclude`d files under `/tmp` or `/var` would be formatted/linted anyway. This matters for our own test temp dirs and any CI under `/private`.

## Tasks

- [x] Locate sm's exclude-path / recursive-walk matching logic
- [x] Determine whether exclude patterns are standardized while enumerated paths keep /private
- [x] If mismatched: write a failing test (exclude a path under a /private-firmlinked temp dir, assert it is skipped)
- [x] Apply the with/without-/private string comparison fix (no per-file stat)

## Source

realm/SwiftLint @ 105980be440759714c35c6f22cffc122f6b8674f (2026-06-22)

## Summary of Changes

**Confirmed the SwiftLint `/private`-firmlink bug DOES reproduce in `sm` — for absolute exclude patterns — and fixed it.**

### Investigation (test-first)

My first hypothesis was that `standardizedFileURL` is lexical-only (the file's own comment at FileIterator.swift:206-209 implies symlink resolution was a pre-Swift-6.0 behavior), so neither side would gain/lose `/private` and the bug wouldn't reproduce. A regression test proved that wrong:

- **Relative** exclude patterns (`**/Generated/**`) are robust across firmlinks — `excludeCandidates` strips the standardized base prefix from the standardized path, so both sides are consistently in the `/var` (firmlink-stripped) form. ✅
- **Absolute** exclude patterns silently failed. Empirically, on this macOS/Swift, `url.standardizedFileURL.path` **strips a leading `/private`**, so the absolute *candidate* is `/var/folders/.../gen.swift`, while a user's absolute pattern (or a `realpath`-resolved input path) keeps `/private/var/.../gen.swift`. They never matched → excluded files were processed anyway. This is exactly realm/SwiftLint #6783.

Debug capture confirming the mismatch:
```
PATTERN        = /private/var/.../project/Generated/**
ABS CANDIDATE  = /var/folders/.../project/Generated/gen.swift   (/private stripped)
```

### Fix

`FileIterator.excludeCandidates(for:)` now also offers the `/private`-toggled absolute form (mirrors SwiftLint's with/without-`/private` comparison, string-only, no per-file `stat`):

```swift
if path.hasPrefix("/private/") {
    out.append(String(path.dropFirst("/private".count)))
} else if path.hasPrefix("/") {
    out.append("/private" + path)
}
```

### Tests

- Added `excludesMatchAbsolutePatternAcrossPrivateFirmlink` — excludes `project/Generated/**` written in BOTH the `/private/var/...` and `/var/...` forms, asserts `gen.swift` is excluded and real files remain. Fails before the fix, passes after.
- `FileIteratorTests` suite green (11 passed).

### Files
- `Sources/SwiftiomaticKit/Syntax/FileIterator.swift`
- `Tests/SwiftiomaticTests/Utilities/FileIteratorTests.swift`
