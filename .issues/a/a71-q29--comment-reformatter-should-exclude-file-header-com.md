---
# a71-q29
title: Comment reformatter should exclude file header comment
status: completed
type: feature
priority: normal
created_at: 2026-04-30T04:27:14Z
updated_at: 2026-04-30T05:23:02Z
sync:
    github:
        issue_number: "532"
        synced_at: "2026-04-30T05:51:02Z"
---

The comment reformatter, which reflows comments to fit within the configured print width, should exclude the file header comment from reformatting.

The file header comment is typically the leading comment block at the top of a source file (license header, copyright notice, etc.) and should be preserved as-authored rather than being reflowed.

## Tasks

- [x] Identify the file header comment region (leading trivia of the first top-level token, before any code)
- [x] Skip reflow/reformatting on comments within that region
- [x] Add a test asserting a multi-line file header comment is preserved verbatim
- [x] Verify non-header comments still reflow within print width


## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Comments/ReflowComments.swift` — at the start of `reflow(_:context:)`, when the token is the first token in the source file, compute the file-header span using the same boundary rules as `FileHeader.findHeaderEnd` (consecutive `.lineComment` / `.blockComment` / `.docBlockComment` separated only by whitespace and single newlines; `.docLineComment` is excluded). Skip any `.line` comment runs whose start index falls inside that span. `///` doc-line runs and all comments in subsequent tokens reflow as before.
- Added two private static helpers: `isFirstTokenInFile(_:)` (checks `previousToken(viewMode: .sourceAccurate) == nil`) and `fileHeaderEnd(in:)` (mirrors `FileHeader`'s boundary logic).
- `Tests/SwiftiomaticTests/Rules/ReflowCommentsTests.swift` — new `preservesFileHeaderComment` test: a multi-line `//` header is preserved verbatim while a `///` doc comment immediately below it still reflows to fit `lineLength`.

Status is `review` pending the test-suite run already in flight in another agent's session.
