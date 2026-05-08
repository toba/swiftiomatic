---
# q37-9ah
title: '`useWeakLetForUnreassigned` misses cross-class assignments'
status: completed
type: bug
priority: high
created_at: 2026-05-08T19:05:43Z
updated_at: 2026-05-08T19:18:42Z
sync:
    github:
        issue_number: "666"
        synced_at: "2026-05-08T19:20:44Z"
---

\`useWeakLetForUnreassigned\` flags a \`weak var\` as unassigned even when it is assigned by a sibling class's init via property access on the instance.

## Repro

\`\`\`swift
class Child: Human {
    weak var parent: Parent?  // ← lint flags as never-reassigned
}

class Parent: Human {
    let children: [Human]

    init(name: String, children: [Child]) {
        self.children = children
        super.init(name: name)

        for child in children { child.parent = self }  // ← reassignment, not detected
    }
}
\`\`\`

\`sm lint\`:

\`\`\`
DumpTests.swift:608:18: warning: [useWeakLetForUnreassigned] 'parent' is declared 'weak var' but never reassigned — prefer 'weak let' (SE-0481)
\`\`\`

Following the suggestion to \`weak let parent: Parent?\` produces a compile error in \`Parent.init\` (\`child.parent = self\` becomes invalid because \`parent\` is now immutable).

## Expected

The rule should consider any assignment of the form \`<expr>.<property>\` where the property type matches and the assignment target's class matches the declaring class — including assignments from sibling/related classes — before recommending \`weak let\`.

A safer heuristic if reflection across types is hard: only flag when the property is private/fileprivate (so mutation must happen in the same file/scope and can be statically checked).



## Summary of Changes

- `UseWeakLetForUnreassigned` now only flags `weak var` properties declared `private` or `fileprivate`. At broader access levels (default `internal`, `package`, `public`, `open`) reassignment can occur from outside the declaring file via `instance.property = …`, which the AST cannot prove absent without type resolution — so we conservatively skip those.
- Updated existing tests to mark intentionally-flagged properties `private`/`fileprivate`.
- Added regression test `internalWeakVarNotFlagged` covering the cross-class repro from the issue, and `fileprivateWeakVarFlagged` confirming `fileprivate` still trips the rule.

Files:
- `Sources/SwiftiomaticKit/Rules/Declarations/UseWeakLetForUnreassigned.swift`
- `Tests/SwiftiomaticTests/Rules/UseWeakLetForUnreassignedTests.swift`
