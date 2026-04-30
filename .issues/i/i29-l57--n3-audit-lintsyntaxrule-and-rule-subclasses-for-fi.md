---
# i29-l57
title: 'N3: Audit LintSyntaxRule and rule subclasses for final / static'
status: ready
type: task
priority: low
created_at: 2026-04-30T15:59:35Z
updated_at: 2026-04-30T15:59:35Z
parent: 6xi-be2
sync:
    github:
        issue_number: "538"
        synced_at: "2026-04-30T16:27:54Z"
---

**Location:** `Sources/SwiftiomaticKit/Syntax/Linter/LintSyntaxRule.swift:3, 13, 16, 17`

Lint flags:
- `LintSyntaxRule` should be `final class` — but it's the base class for every lint rule, so the actionable form is `final` on the *subclasses*.
- `class var key/group/defaultValue` could be `static var` *only if* no subclass needs override-via-vtable through an existential.

## Potential performance benefit

`static var` over `class var` removes a vtable indirection at metatype member access; tiny but per-call. `final` on subclasses lets the compiler devirtualize visitor calls. Likely small but real.

## Reason deferred

Mechanical audit across ~200 rule classes. Several subclasses today already use `override class var` mixed with `override static var`, which suggests the repo isn't consistent. Need to (a) confirm whether any code path actually relies on `class var` virtual dispatch through `any SyntaxRule.Type`, then (b) flip the rest to `static`. Easier to do in one PR than rule-by-rule.
