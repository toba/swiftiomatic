---
# i29-l57
title: 'N3: Audit LintSyntaxRule and rule subclasses for final / static'
status: completed
type: task
priority: low
created_at: 2026-04-30T15:59:35Z
updated_at: 2026-04-30T19:49:10Z
parent: 6xi-be2
sync:
    github:
        issue_number: "538"
        synced_at: "2026-04-30T20:01:24Z"
---

**Location:** `Sources/SwiftiomaticKit/Syntax/Linter/LintSyntaxRule.swift:3, 13, 16, 17`

Lint flags:
- `LintSyntaxRule` should be `final class` — but it's the base class for every lint rule, so the actionable form is `final` on the *subclasses*.
- `class var key/group/defaultValue` could be `static var` *only if* no subclass needs override-via-vtable through an existential.

## Potential performance benefit

`static var` over `class var` removes a vtable indirection at metatype member access; tiny but per-call. `final` on subclasses lets the compiler devirtualize visitor calls. Likely small but real.

## Reason deferred

Mechanical audit across ~200 rule classes. Several subclasses today already use `override class var` mixed with `override static var`, which suggests the repo isn't consistent. Need to (a) confirm whether any code path actually relies on `class var` virtual dispatch through `any SyntaxRule.Type`, then (b) flip the rest to `static`. Easier to do in one PR than rule-by-rule.



## Summary of Changes

Audit results — no code change required:

1. **`final` on subclasses**: verified all rule subclasses across `Sources/SwiftiomaticKit/Rules/` are already declared `final class` (`grep -rE '^[a-z]* class [A-Z]' Sources/SwiftiomaticKit/Rules/` shows zero non-final entries). The lint flag on `LintSyntaxRule` itself is the base class — it cannot be `final` because every rule inherits from it.

2. **`class var` → `static var` for `key`/`group`/`defaultValue`**: not safe to flip. `Configuration.isActive(rule:)`, `Context.shouldFormat(ruleType:node:)`, `SyntaxFindingCategory`, and `ConfigurationRegistry.allRuleTypes` all dispatch through `any SyntaxRule.Type` existentials. `class var` ensures the metatype access goes through the vtable so the subclass override is selected; `static var` would bind to the static base type and return the wrong key/group. The doc comment on `LintSyntaxRule` and `StaticFormatRule` already records this.

3. **Mixed `override class var` / `override static var` in subclasses**: both forms work for final subclasses. Cosmetic inconsistency, not a correctness or perf issue. Bundling a normalization pass into a future generator/dispatcher refactor (P3/P9) is the right time.
