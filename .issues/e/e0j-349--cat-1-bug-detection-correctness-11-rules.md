---
# e0j-349
title: 'Cat 1: Bug Detection & Correctness (11 rules)'
status: in-progress
type: feature
priority: normal
created_at: 2026-04-15T00:27:58Z
updated_at: 2026-04-25T17:35:19Z
parent: qlt-10c
sync:
    github:
        issue_number: "320"
        synced_at: "2026-04-25T17:39:16Z"
---

High-value lint rules that catch real bugs the compiler doesn't flag.

| SwiftLint Rule | Swiftiomatic Name | Scope | Description |
|---|---|---|---|
| `identical_operands` | IdenticalOperands | `.lint` | `x == x` is almost always a copy-paste bug |
| `duplicate_conditions` | DuplicateConditions | `.lint` | Same condition in if/else-if chain |
| `duplicated_key_in_dictionary_literal` | DuplicateDictionaryKeys | `.lint` | Duplicate dictionary keys crash at runtime |
| `capture_variable` | MutableCapture | `.lint` | Mutable var in closure capture list — data race risk |
| `unhandled_throwing_task` | UnhandledThrowingTask | `.lint` | Task {} silently swallows thrown errors |
| `discarded_notification_center_observer` | RetainNotificationObserver | `.lint` | Must store the returned observer token |
| `overridden_super_call` | RequireSuperCall | `.lint` | Missing super.viewDidLoad(), setUp(), etc. |
| `compiler_protocol_init` | NoLiteralProtocolInit | `.lint` | Direct init of ExpressibleByArrayLiteral etc. |
| `unused_setter_value` | UnusedSetterValue | `.lint` | Setter never references `newValue` |
| `unused_control_flow_label` | UnusedControlFlowLabel | `.lint` | Dead break/continue label |
| `invisible_character` | InvisibleCharacters | `.lint` | Zero-width chars in string literals (U+200B, U+FEFF, etc.) |



---

## Implementation phases

**Phase 1 — Schema strictness**
- [x] Add `unevaluatedProperties` support to `JSONSchemaNode`
- [x] Set `unevaluatedProperties: false` on lint-only rule schema nodes in `ConfigurationSchemaGenerator.ruleSchemaNode`
- [x] Drop dead `rewrite` decode from `LintOnlyValue.init(from:)`
- [x] Add schema test asserting `rewrite` is rejected on a lint-only rule entry
- [x] Fix stale generator paths after Layout/Syntax Rules unification
- [x] Regenerate `schema.json`, review diff
- [ ] Build + test green (blocked: unrelated Configuration.swift error from another agent's WIP — Generator product compiles cleanly)

**Phase 2 — 11 rules**
- [ ] IdenticalOperands (opt-in)
- [ ] DuplicateConditions (.error)
- [ ] DuplicateDictionaryKeys
- [ ] MutableCapture
- [ ] UnhandledThrowingTask (.error, opt-in)
- [ ] RetainNotificationObserver (opt-in)
- [ ] RequireSuperCall (opt-in, custom config)
- [ ] NoLiteralProtocolInit
- [ ] UnusedSetterValue
- [ ] UnusedControlFlowLabel
- [ ] InvisibleCharacters (.error, custom config)
