---
# yt4-ims
title: Add exclude config option with glob support to skip folders during recursive lint/format
status: completed
type: feature
priority: normal
created_at: 2026-05-08T15:13:40Z
updated_at: 2026-05-08T15:38:20Z
sync:
    github:
        issue_number: "660"
        synced_at: "2026-05-08T15:45:11Z"
---

## Goal

Allow users to exclude paths from `sm lint`/`sm format` recursive walks via configuration. Common case: skip `.build/`, `Carthage/`, generated code, vendor directories.

## Proposal

Add a top-level `excludes` array of glob patterns to `swiftiomatic.json`:

```json
{
  "excludes": [
    ".build/**",
    "**/Generated/**",
    "vendor/**"
  ]
}
```

## Implementation

- Add `Excludes` LayoutRule with `[String]` default `[]`
- Add a small `Glob` matcher supporting `*`, `?`, `[abc]`, and `**` (matches across path separators)
- Plumb excludes into `FileIterator` so directories matching a pattern are pruned (no recursion) and matching files are skipped
- Match against a path **relative to the iterator's working directory** so patterns like `.build/**` work consistently
- `Frontend.processURLs` loads the configuration from cwd before iterating to obtain excludes
- Update `Generator` to support array-of-string layout default values (new `SchemaValueType.stringArray`)
- Tests in `FileIteratorTests`

## Out of scope

- `.gitignore` integration (separate issue if desired)
- Per-file include/exclude precedence rules



## Summary of Changes

- **`Excludes` LayoutRule** (`Sources/SwiftiomaticKit/Rules/FileSelection/Excludes.swift`) — new top-level `excludes` config field, `[String]` default `[]`.
- **`Glob` matcher** (`Sources/SwiftiomaticKit/Syntax/Glob.swift`) — translates shell-style globs to `NSRegularExpression`. Supports `*`, `?`, `[…]` (with `!` negation), and `**` across path separators.
- **`FileIterator`** — accepts `excludes:` parameter, prunes matching directories via `enumerator.skipDescendants()`, and skips matching files. Tries patterns relative to the input directory, working directory, and absolute path so `vendor/**` works regardless of how sm is invoked.
- **`Frontend.processURLs`** — loads configuration from the first input path before iterating to obtain excludes.
- **Generator** — added `SchemaValueType.stringArray` case to detect array-typed layout defaults; emits `{ "type": "array", "items": { "type": "string" } }` in `schema.json`.
- **Tests** — `GlobTests` (8 cases) and two new `FileIteratorTests` cases covering directory pruning and file skipping.
- **`schema.json`** regenerated.

Smoke-tested manually: `vendor/**` and `**/Skip.swift` both correctly exclude `vendor/Skip.swift` from a recursive lint.
