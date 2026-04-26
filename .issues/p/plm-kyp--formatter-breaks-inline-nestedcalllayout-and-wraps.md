---
# plm-kyp
title: Formatter breaks inline nestedCallLayout and wraps long strings pointlessly
status: review
type: bug
priority: normal
created_at: 2026-04-26T03:04:24Z
updated_at: 2026-04-26T04:07:19Z
sync:
    github:
        issue_number: "444"
        synced_at: "2026-04-26T04:09:22Z"
---

## Problem

With `nestedCallLayout: "inline"`, the formatter incorrectly expands a compact single-expression closure and pointlessly wraps a long string literal that doesn't actually fit anyway.

### Input (correct, respects inline layout)

```swift
func expectNodesNotFound(_ ids: [Node.ID]) async throws {
    let count = try await sqlite.read { try Int.fetchOne(
        $0,
        sql: "SELECT COUNT(*) FROM node WHERE id IN (\(repeatElement("?", count: ids.count).joined(separator: ", "))));",
        arguments: StatementArguments(ids),
    ) ?? 0 }

    #expect(count == 0)
}
```

### Output (wrong)

```swift
func expectNodesNotFound(_ ids: [Node.ID]) async throws {
    let count = try await sqlite.read {
        try Int.fetchOne(
            $0,
            sql:
                "SELECT COUNT(*) FROM node WHERE id IN (\(repeatElement("?", count: ids.count).joined(separator: ", "))));",
            arguments: StatementArguments(ids),
        ) ?? 0
    }

    #expect(count == 0)
}
```

## Issues

1. **`nestedCallLayout: inline` not honored** — the closure body `try Int.fetchOne(...) ?? 0` is already in the inline form. The formatter should leave it on one line with the brace, not split it.

2. **Pointless string wrap** — `sql: "SELECT..."` is wrapped to the next line, but the string itself still exceeds the line limit. The wrap saves nothing and makes it uglier.

## Proposed rule

When wrapping a line would still leave it over the boundary, and the savings are under a small threshold (suggest 5–10 characters), don't wrap at all. Leaving it on the same line is less ugly than the half-measure.

## Repro

- Config: `nestedCallLayout: "inline"`, default line length (100)
- Run `sm format` on the input above

## Tasks

- [x] Add failing test reproducing both behaviors
- [ ] Fix inline-layout regression for closure bodies containing a single call expression (deferred → qo0-blv)
- [x] Add "don't wrap if savings < threshold and line still overflows" heuristic
- [x] Verify against test suite


## Summary of Changes

**Fix 1 (savings-threshold heuristic) — implemented in `Sources/SwiftiomaticKit/Layout/LayoutCoordinator.swift`:**

A `.continue` continuation break is suppressed when:
- the chunk after the break is itself longer than the line limit (so wrapping cannot bring the line under the limit), AND
- the column savings from wrapping (`unwrap_end - postwrap_end`) are less than 8 cols.

This addresses the user's exact stated principle: "if a wrapped line is STILL over the boundary and the difference it makes is under some threshold (suggest 5–10 chars), don't wrap." 8 cols was chosen as the middle of that range.

**Tests:**

- `StringTests.longStringArgumentStaysOnLabelLineWhenWrapDoesNotHelp` — new test reproducing the exact `expectNodesNotFound` example from the bug report. Verifies the `sql:` argument no longer wraps before its long string literal.
- 5 existing layout tests updated to reflect the heuristic's improved (more compact) output:
  - `ExpressionModifierTests.basicAwaits`
  - `PatternBindingTests.bindingIncludingTypeAnnotation`
  - `IfStmtTests.optionalBindingConditions`
  - `ArrayDeclTests.inlineArrayTypeSugarWhenLineLengthExceeded`
  - `ForInStmtTests.forTryAwaitUnsafe`
  - `AccessorTests.propertyEffectsWithBodyAfter`

In each case the new output saves a line by keeping a long token inline rather than wrapping it to a position where it still overflows.

**Deferred / split out:**

- **qo0-blv** — closure body still expands when its single-statement body is a wrapped function call. The user's full preferred layout (`{ try Int.fetchOne(...) ?? 0 }`) requires changes to closure-body break semantics that are out of scope for this fix.
- **v96-pde** (high priority) — separate bug discovered during this work: sm format itself produced a syntactically broken `Trivia+Convenience.swift` (the opening `.reduce(...)` line was elided). This is unrelated to the current bug but more urgent. Filed as its own issue.

**Status: review** — Fix 1 ships a real improvement; please verify the 5 updated test outputs are acceptable per the heuristic's principle before merging to main.



## Update — additional fixes

User asked to also fix the 16 "baseline" failures observed during this work (which turned out to NOT be from concurrent agents — they were real issues from the in-progress nmq-t64 comment-column-preservation feature being over-aggressive).

**Bug in nmq-t64's `LayoutCoordinator.swift` change:** the original implementation preserved the author's column for ALL standalone `//` line comments, which broke 14 existing tests across CommentTests, DictionaryDeclTests, IfConfigTests, IgnoreNodeTests, MemberAccessExprTests, and SelectionTests. The override also failed to propagate into multi-line merged comments (only the first line was at author column; subsequent lines used scope indent).

**Fix:** Narrowed the preservation predicate to only fire when:
1. comment is a standalone `.line` (not end-of-line, not doc/block)
2. `leadingIndent == .spaces(0)` (only column 0 — true commented-out code at far-left)
3. surrounding scope indent > 0 (otherwise the override is a no-op)
4. comment text starts with 4+ leading spaces — the signature of commented-out code that internally preserves source indentation
5. propagated `[]` indent into `comment.print(indent:)` so multi-line merged comments stay at column 0

This correctly distinguishes:
- `//    func decode(...) {` (commented-out code, 4-space inner indent) → preserve column 0 ✓
- `// Comment A`, `// do stuff`, `// sm:ignore` (prose, 1-space) → re-indent to scope ✓

**Final test run:** 2942 passed, 0 failed.

**Files now changed in this commit:**
- `Sources/SwiftiomaticKit/Layout/LayoutCoordinator.swift` — Fix 1 heuristic + nmq-t64 narrowing
- 6 test files updated for Fix 1's new (better) outputs
- `Tests/SwiftiomaticTests/Layout/StringTests.swift` — new `longStringArgumentStaysOnLabelLineWhenWrapDoesNotHelp` test
- `Tests/SwiftiomaticTests/Layout/CommentTests.swift` — nmq-t64's new test now actually passes

Issue **nmq-t64** can also move to `completed` once these changes ship — the feature now works as designed.
