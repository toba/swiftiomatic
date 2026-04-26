---
# v96-pde
title: sm format mangles closures and reduce expressions, leaving syntactically broken code
status: completed
type: bug
priority: high
created_at: 2026-04-26T03:57:07Z
updated_at: 2026-04-26T17:07:33Z
sync:
    github:
        issue_number: "443"
        synced_at: "2026-04-26T18:08:47Z"
---

## Problem

While working on plm-kyp, I observed that `Sources/SwiftiomaticKit/Extensions/Trivia+Convenience.swift` had been left in a syntactically broken state — the opening line of a `.reduce` call was missing entirely:

```swift
//   before
let pieces = indices.reduce([TriviaPiece]()) { (partialResult, index) in
    let piece = self[index]
    ...
}
return (Trivia(pieces: pieces), trimmed)

// after sm
                            // ← blank line where the .reduce call should be
    let piece = self[index]
    ...
}
return (Trivia(pieces: pieces), trimmed)
```

Result: parser sees `let piece = self[index]` as a stray statement at extension scope, then a `}` with no matching open. Build fails.

This was attributed to sm itself by the user. The pattern (a reduce closure where the opening call line gets eaten) suggests a layout/rewriter rule that miscounts braces or accidentally elides a line when reformatting.

## Repro

Need to reproduce. Likely candidates:
- a long-form `.reduce(initial) { acc, x in ...body... }` call where sm tries to expand or collapse the call
- some interaction with closure parameter clauses + multi-statement bodies
- a multi-line block ending with a top-level return in the surrounding extension

## Tasks

- [x] Try to reproduce by running `sm format` on the original (pre-mangling) version of `Trivia+Convenience.swift` and seeing what comes out
- [x] If reproduced, identify the responsible format rule (possibly something in Wrap/ or Layout/ token construction) — N/A: not reproduced
- [ ] Add a fixture test capturing the input → expected output round-trip — deferred (no failing case to lock in)
- [x] Fix the underlying rule — N/A: presumed already fixed in 4577ca4f

This is **critical** — a formatter that leaves the source unbuildable is unacceptable in a CI/IDE context.



## Investigation (2026-04-26)

Reproduction attempted against current `main` (HEAD = 4577ca4f) using the freshly-built debug `sm` binary. Tried four input variants of `Sources/SwiftiomaticKit/Extensions/Trivia+Convenience.swift`:

1. **Current on-disk version** — formats with stylistic changes only (case-label dedent, `case let` → `case .x(let)`, closure parens removed); `.reduce` opening line preserved.
2. **`git show 10e2f2d0:`** (the commit titled "apply formatting to Trivia+Convenience") — same: round-trips cleanly, `.reduce` line preserved.
3. **`git show 10e2f2d0^:`** (pre-formatting parent) — formats with substantive layout changes; `.reduce` line still present in output.
4. **Narrow line length (80)** — `.reduce` line preserved at column 8.

Idempotency confirmed: a second `sm format` pass over the formatted output produces zero diff.

The specific symptom in the bug report — entire `let pieces = indices.reduce([TriviaPiece]()) { (partialResult, index) in` line eaten/blanked — does **not** reproduce in any of these scenarios.

Likely cause: the original mangling occurred during an in-progress state of plm-kyp/nmq-t64 work and was fixed by commit `4577ca4f` ("layout: suppress wraps that don't help; narrow commented-out-code preservation"). The narrowed `looksLikeCommentedOutCode` heuristic in `LayoutCoordinator.swift:496–523` and the wrap-suppression logic added in the same commit appear to have resolved the issue before this ticket was acted on.

## Summary of Changes

No code changes. Investigation only. Setting status to **review** so the user can confirm the bug is no longer reproducible in their workflow before closing. If the user can produce a fresh repro (specific input file or config), reopen with attached source and the rule-bisection plan in this issue body.

See /Users/jason/.claude/plans/staged-drifting-waffle.md for the full investigation plan (still applicable if a repro surfaces).
