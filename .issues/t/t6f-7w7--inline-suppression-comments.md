---
# t6f-7w7
title: Inline suppression comments
status: completed
type: feature
priority: critical
created_at: 2026-04-10T22:25:29Z
updated_at: 2026-04-10T22:27:39Z
parent: pms-xpz
sync:
    github:
        issue_number: "166"
        synced_at: "2026-04-11T01:01:47Z"
---

Already fully implemented using the `sm:` prefix.

### Supported syntax

```swift
let x = foo // sm:disable:this rule_id
// sm:disable:next rule_id
let y = bar
// sm:disable rule_id
...code...
// sm:enable rule_id
// sm:disable all
// sm:disable:next force_try - Explanation here
```

### Implementation

- `Command` model (`Sources/Swiftiomatic/Models/Command.swift`) — parses `sm:` directives with action, modifier, rule identifiers, and trailing comments
- `CommandVisitor` (`Sources/Swiftiomatic/Support/Visitors/CommandVisitor.swift`) — AST visitor that extracts commands from line-comment trivia
- `RuleIdentifier` (`Sources/Swiftiomatic/Models/RuleIdentifier.swift`) — supports `.all` and `.single(identifier:)`
- Modifiers: `:previous`, `:this`, `:next`, and range-based (no modifier)
- Validation rules: `SuperfluousDisableCommandRule`, `BlanketDisableCommandRule`, `InvalidCommandRule`

## Tasks

- [x] Parse `// sm:` comments during syntax visiting
- [x] Support `:this`, `:next`, `:previous`, and range (disable/enable pairs)
- [x] Support `// sm:disable all` to suppress all rules
- [x] Filter diagnostics against suppression map before output
- [x] Warn on unused/invalid suppression comments (dedicated rules)
- [x] Add tests

## Summary of Changes

No changes needed — this was already complete.
