---
# v96-pde
title: sm format mangles closures and reduce expressions, leaving syntactically broken code
status: ready
type: bug
priority: high
created_at: 2026-04-26T03:57:07Z
updated_at: 2026-04-26T03:57:07Z
sync:
    github:
        issue_number: "443"
        synced_at: "2026-04-26T04:09:22Z"
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

- [ ] Try to reproduce by running `sm format` on the original (pre-mangling) version of `Trivia+Convenience.swift` and seeing what comes out
- [ ] If reproduced, identify the responsible format rule (possibly something in Wrap/ or Layout/ token construction)
- [ ] Add a fixture test capturing the input → expected output round-trip
- [ ] Fix the underlying rule

This is **critical** — a formatter that leaves the source unbuildable is unacceptable in a CI/IDE context.
