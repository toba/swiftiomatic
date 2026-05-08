---
# 751-jwp
title: support multiple rules in a single 'sm:ignore:next' directive
status: completed
type: feature
priority: normal
created_at: 2026-05-08T02:41:52Z
updated_at: 2026-05-08T02:51:58Z
sync:
    github:
        issue_number: "645"
        synced_at: "2026-05-08T02:54:15Z"
---

## Current

```swift
// sm:ignore:next ruleA ruleB - reason
let x: Foo!
```

Only the first rule (`ruleA`) is suppressed; `ruleB` still fires.

Workaround — stack directives:

```swift
// sm:ignore:next ruleA - reason
// sm:ignore:next ruleB - reason
let x: Foo!
```

## Request

Accept multiple rules in a single directive, separated by space and/or comma:

```swift
// sm:ignore:next ruleA ruleB - reason
// sm:ignore:next ruleA, ruleB - reason
```

Reduces directive bloat for declarations that legitimately trip multiple rules (e.g. `weak var foo: Foo!` triggers both `useWeakLetForUnreassigned` and `noImplicitlyUnwrappedOptionals`).

## Repro

Thesis `DOM/Sources/DocumentNode.swift:16-17` — currently uses two stacked directives.



## Summary of Changes

Modified `RuleStatusCollectionVisitor.ruleStatusDirectiveMatch` in `Sources/SwiftiomaticKit/Syntax/RuleMask.swift` to accept space-separated rule lists in all `// sm:ignore`, `// sm:ignore:next`, and trailing-form directives.

**Logic**: After parsing the first rule, subsequent tokens continue the rule list when either (a) a comma separated them (existing behavior), or (b) the token normalizes to a known rule key registered in `ConfigurationRegistry.allRuleKeys`. The first whitespace-separated, non-comma token that doesn't resolve to a known rule ends the list — everything after is treated as a free-form comment.

This preserves the existing `// sm:ignore:next noLeadingUnderscores macro requires this` semantics (where `macro` isn't a known rule, so it terminates the list as a comment) while enabling `// sm:ignore:next useWeakLetForUnreassigned noImplicitlyUnwrappedOptionals - reason`.

**Files changed**:
- `Sources/SwiftiomaticKit/Configuration/ConfigurationRegistry.swift` — added `allRuleKeys: Set<String>`
- `Sources/SwiftiomaticKit/Syntax/RuleMask.swift` — parser change + updated docstring
- `Tests/SwiftiomaticTests/Core/RuleMaskTests.swift` — three new tests covering lone-line, `:next`, and trailing forms
