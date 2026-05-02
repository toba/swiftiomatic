---
# fry-ger
title: InlineBodies drops trailing comment when collapsing to single line
status: completed
type: bug
priority: normal
created_at: 2026-05-02T16:53:14Z
updated_at: 2026-05-02T17:30:44Z
sync:
    github:
        issue_number: "628"
        synced_at: "2026-05-02T17:32:31Z"
---

## Repro

```swift
public extension APIResponse where T == Data {
    var body: String {
        String(decoding: data, as: UTF8.self) // sm:ignore useFailableStringInit
    }
}
```

After running with the inline-bodies rule enabled, becomes:

```swift
public extension APIResponse where T == Data {
    var body: String { .init(decoding: data, as: UTF8.self) }
}
```

The trailing comment is silently dropped. This applies to any trailing comment on the body's single statement — not specifically `sm:ignore`. The `sm:ignore` case is the most damaging because losing the directive can re-trigger findings and cause undesired rewrites elsewhere, but plain comments are also lost.

## Expected

When collapsing the body to a single line, preserve the trailing comment by promoting it to a leading comment on the line above:

```swift
public extension APIResponse where T == Data {
    // sm:ignore useFailableStringInit
    var body: String { .init(decoding: data, as: UTF8.self) }
}
```

This keeps the ignore directive attached to the same statement (sm:ignore applies to the next line) and preserves user intent.

## Tasks

- [x] Add failing test in InlineBodies tests covering the trailing-comment case
- [x] Update the inline-bodies rule to skip inlining when comments would be lost
- [x] Verify sm:ignore directives still suppress the intended rule
- [x] Run full test suite to confirm no regressions



## Summary of Changes

Fixed in `Sources/SwiftiomaticKit/Rules/Wrap/LayoutSingleLineBodies.swift` by adding comment detection that prevents inlining when any comment is present in the body trivia (left-brace trailing, statement leading/trailing, right-brace leading).

**Decision**: Rather than hoist the trailing comment above the collapsed line (which is ambiguous when multiple comments are scattered around the body and risks losing the `sm:ignore` line-attachment semantics), we conservatively skip inlining when any comment exists. This preserves the comment exactly where the user wrote it — strictly safer than hoisting, and matches the existing behavior already used by `shouldInlineCollection` for collection literals.

### Changes

- `LayoutSingleLineBodies.canInline(_:)` now returns false when `bodyHasComments(_:)` is true. Covers if/guard/function/init/for/while/repeat/observer.
- New `accessorBlockHasComments(_:statementTrailing:)` helper guards property and subscript getter inlining (which use accessor blocks rather than CodeBlockSyntax).
- Added 5 tests in `SingleLineBodiesInlineTests` covering: computed property with `sm:ignore` trailing comment, property with plain trailing comment, function with trailing comment, guard with trailing comment, if with leading comment.

Full test suite: 3205 passed, 0 failed.
