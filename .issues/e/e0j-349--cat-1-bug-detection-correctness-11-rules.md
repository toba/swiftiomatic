---
# e0j-349
title: 'Cat 1: Bug Detection & Correctness (11 rules)'
status: review
type: feature
priority: normal
created_at: 2026-04-15T00:27:58Z
updated_at: 2026-04-25T18:28:53Z
parent: qlt-10c
sync:
    github:
        issue_number: "320"
        synced_at: "2026-04-25T18:30:27Z"
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
- [x] Build + test green

**Phase 2 — 11 rules**
- [x] IdenticalOperands (opt-in)
- [x] DuplicateConditions (.error)
- [x] DuplicateDictionaryKeys
- [x] MutableCapture
- [x] UnhandledThrowingTask (.error, opt-in)
- [x] RetainNotificationObserver (opt-in)
- [x] RequireSuperCall (opt-in, custom config)
- [x] NoLiteralProtocolInit
- [x] UnusedSetterValue
- [x] UnusedControlFlowLabel
- [x] InvisibleCharacters (.error, custom config)


---

## Summary of Changes

**Phase 1 — Schema strictness** (already complete in earlier session, verified green here)

**Phase 2 — 11 new lint rules**

All under `Sources/SwiftiomaticKit/Rules/<group>/`, each with a matching test file in `Tests/SwiftiomaticTests/Rules/`:

| Rule | Group | Severity | Notes |
|---|---|---|---|
| `IdenticalOperands` | conditions | warn (opt-in) | flags `x == x`, `foo.a < foo.a`, etc. across all 8 comparison operators |
| `DuplicateConditions` | conditions | error | walks if/else-if chains and switch case lists; order-insensitive condition sets |
| `DuplicateDictionaryKeys` | literals | warn | static keys only (literals, identifiers, member access); skips dynamic keys like `UUID()`/`#line` |
| `MutableCapture` | closures | warn | pre-scans file for `var` names, flags matching closure captures (skips `weak`/`unowned`/`x = self.x`/`self`) |
| `UnhandledThrowingTask` | closures | error (opt-in) | catches `Task { try ... }` with implicit error type whose result isn't consumed; understands `do/catch`, `try?`, `Result {}` |
| `RetainNotificationObserver` | idioms | warn (opt-in) | flags discarded `addObserver(forName:object:queue:...)` calls; honors `@discardableResult` |
| `RequireSuperCall` | declarations | warn (opt-in) | custom config `requireSuperCall.methodNames` — defaults cover UIKit/AppKit/XCTest lifecycle methods |
| `NoLiteralProtocolInit` | literals | warn | flags direct calls to `ExpressibleBy*` initializers (e.g. `Set(arrayLiteral: 1, 2)`) |
| `UnusedSetterValue` | declarations | warn | flags `set { ... }` blocks that never reference `newValue` (or named param); allows empty `override` setters |
| `UnusedControlFlowLabel` | redundancies | warn | flags labels on `while`/`for`/`switch`/`repeat` not referenced by any `break`/`continue` |
| `InvisibleCharacters` | literals | error | custom config `invisibleCharacters.additionalCodePoints`; defaults: U+200B, U+200C, U+FEFF |

**Verification:** full test suite green — 2669 passed, 0 failed (added 84 new tests across 11 files).

**Deferred:** the SwiftLint reference for `MutableCapture` uses SourceKit indexing for cross-file resolution; ours is a single-file syntactic heuristic. Captures of vars declared in *other* files (globals, instance vars on a separately-defined type) are not detected. Acceptable for v1; can revisit if false-negative reports come in.
