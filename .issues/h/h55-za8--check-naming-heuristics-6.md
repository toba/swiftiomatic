---
# h55-za8
title: 'Check: Naming heuristics (§6)'
status: completed
type: task
priority: normal
created_at: 2026-02-27T21:34:54Z
updated_at: 2026-02-27T21:49:56Z
parent: 52u-0w0
blocked_by:
    - w7e-hbx
---

SyntaxVisitor that checks Swift API Design Guidelines naming conventions.

## What grep does today
- Matches `protocol *able` (check -able vs -ing)
- Matches boolean `var is/has/can` (assertion check)
- Matches `func make` (factory method pattern)

## What AST enables beyond grep
- [ ] **Protocol naming: -able vs -ing** — find protocols ending in `-able` and check if conforming types *perform* the action (should be `-ing`) vs *receive* it (correct as `-able`). Requires checking the protocol's method signatures for directionality
- [ ] **Mutating/non-mutating pairs** — find `mutating func sort()` without `func sorted()`, or `func union()` without `mutating func formUnion()`. AST can check the full type for the companion method
- [ ] **Side-effect clarity** — find functions named as nouns that mutate (`func items()` that modifies state) or verbs that don't mutate (`func sort()` that returns a new array)
- [ ] **Boolean property assertions** — verify `Bool` properties read as assertions: `isEmpty`, `hasPrefix`. Flag `Bool` properties like `enabled`, `visible` (should be `isEnabled`, `isVisible`)
- [ ] **Factory method naming** — find `static func` returning `Self` or the enclosing type that don't start with `make`
- [ ] **Argument label quality** — detect first labels that don't form a grammatical phrase with the function name: `add(element:)` should be `add(_:)` since "add element" is a complete phrase
- [ ] **Type names as variable names** — detect `let string: String`, `let array: [Int]` where the variable is named by type not role

## AST nodes to visit
- `ProtocolDeclSyntax` — name suffix analysis, member analysis for action directionality
- `FunctionDeclSyntax` — mutating modifier, return type, naming patterns
- `VariableDeclSyntax` — Bool type check, name pattern for assertions
- `FunctionParameterSyntax` — label analysis relative to function name

## Confidence levels
- `-able` protocol performing actions → medium (needs human judgment on directionality)
- Missing mutating/non-mutating pair → medium
- Bool not reading as assertion → medium
- Factory without `make` prefix → low
- Argument label issues → low (style preference)

## Summary of Changes
- NamingHeuristicsCheck detects Bool naming, factory method prefixes, protocol -able vs -ing
- Tests with fixture
