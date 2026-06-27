---
# mid-kqi
title: 'Port swift-format #1225: #endif followed by a decl — NewlineBehavior branching'
status: completed
type: bug
priority: normal
created_at: 2026-06-27T15:44:44Z
updated_at: 2026-06-27T16:09:51Z
sync:
    github:
        issue_number: "743"
        synced_at: "2026-06-27T16:17:04Z"
---

Port upstream swift-format fix 0ace99790cdd67421f958a9a15afc8f83d4da497 (#1225, fixes #1223).

## Upstream change
`visit(IfConfigDeclSyntax)` unconditionally emitted `.break(.same, size: 0)` after `#endif`. Upstream now branches the NewlineBehavior:
- `.elective` when the #if is inside an attribute list
- `respectsExistingLineBreaks ? .elective : .soft` when nested in a postfix #if
- `.soft` otherwise

Also: forces a hard break after an attribute-list element and when an attribute list ends with an #if (arrangeAttributeList); and changes postfix-#if contextual breaks to `.soft`, dropping the redundant after(poundEndif) break in insertContextualBreaks.

## Tasks
- [x] Locate Swiftiomatic equivalents: visitIfConfigDecl, arrangeAttributeList, insertContextualBreaks postfix-if path
- [x] isNestedInPostfixIfConfig already exists (CommentMovingRewriter.swift)
- [x] Add regression test reproducing the #endif merge; confirmed it failed first
- [x] Port the fix (all three hunks)
- [x] Confirm test passes; full suite green (3469 passed)

Upstream test: Tests/SwiftFormatTests/PrettyPrint/RespectsExistingLineBreaksTests.swift


## Summary of Changes

**This bug DOES reproduce in Swiftiomatic** — confirmed by a failing test before the fix. With `respectsExistingLineBreaks: false`, an attribute-block `#if @frozen #endif` on a declaration merged the `#endif` onto the decl (`#endif struct S {}`) and was non-idempotent (second pass collapsed further to `#endifstruct S {}`).

Root cause matched upstream #1223: the break after `#endif` was emitted as a single `.break(.same, size: 0)` with default `.elective` newlines, so with line-break preservation off there was nothing to force the newline in the attribute-list case.

Ported all three upstream hunks (swift-format 0ace99790cdd67421f958a9a15afc8f83d4da497):

1. **`visitIfConfigDecl`** (TokenStream+MembersAndBlocks.swift) — branch the after-`#endif` `NewlineBehavior`: `.elective` inside an attribute list, `respectsExistingLineBreaks ? .elective : .soft` when nested in a postfix `#if`, `.soft` otherwise. Reused the existing `isNestedInPostfixIfConfig` helper.
2. **`arrangeAttributeList`** (TokenStream+Helpers.swift) — force a hard break after an `#if`-block attribute element, and after the whole attribute list when it ends with an `#if` (`endsWithIfConfig`). **This hunk is what actually fixes our failing case** — the attribute-list `#if` keeps an elective `#endif` break (so it can hug the decl when breaks are respected), and the hard break here guarantees separation otherwise.
3. **postfix-if path in `insertContextualBreaks`** (TokenStream+Breaks.swift) — `.soft` newlines on the clause `poundKeyword` and `poundEndif` contextual breaks; removed the now-redundant `after(poundEndif, .break(.same, size: 0))` since `visit(IfConfigDeclSyntax)` (which dispatches to `visitIfConfigDecl` for every node, postfix configs included) now emits the postfix-aware break. Verified the dispatch in Generated/TokenStream+Generated.swift.

Added regression test `RespectExistingLineBreaksTests.ifConfigKeepsRequiredLineBreakAfterEndif` (upstream-adapted: struct + switch cases at relb=false). Expected output reflects Swiftiomatic's actual layout — note two pre-existing, out-of-scope `#if` divergences from upstream that this fix does not address: switch cases inside `#if` aren't indented (`case 1: f()` stays at col 0), and a postfix member-chain `#if` leaves `.foo()` at col 0. Both predate this change and are unrelated to the `#endif` merge.

Full suite green: 3469 passed, 0 failed. Output idempotent.
