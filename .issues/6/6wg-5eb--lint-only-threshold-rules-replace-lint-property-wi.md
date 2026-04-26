---
# 6wg-5eb
title: 'Lint-only threshold rules: replace ''lint'' property with ''enabled'''
status: ready
type: bug
priority: normal
created_at: 2026-04-26T17:56:51Z
updated_at: 2026-04-26T17:57:19Z
sync:
    github:
        issue_number: "447"
        synced_at: "2026-04-26T18:08:47Z"
---

Lint-only rules with dual error/warning thresholds are configured like:

```json
"typeBodyLength": { "lint": "warn", "error": 350, "warning": 250 },
"lineLengthLimit": { "lint": "warn", "error": 200, "warning": 120 },
"closureBodyLength": { "lint": "warn", "error": 50, "warning": 30 },
"functionBodyLength": { "lint": "warn", "error": 100, "warning": 50 },
"associatedValueCount": { "lint": "warn", "error": 6, "warning": 5 },
```

The `lint` property doesn't make sense here — the severity mechanism for these rules is different. They emit a **warning** finding once the value crosses the warning threshold and an **error** finding once it crosses the error threshold. The severity is encoded in the thresholds themselves, not in a separate `lint` field.

## Problem

- The `lint` property implies a single severity (`warn`/`error`/`off`) for the rule, which contradicts the dual-threshold model.
- Users see a redundant/conflicting field in their config and schema.
- Schema documentation and tooling treat these rules the same as boolean lint rules, which they are not.

## Proposed change

Replace the `lint` property on dual-threshold rules with an `enabled` boolean:

```json
"typeBodyLength": { "enabled": true, "error": 350, "warning": 250 },
"lineLengthLimit": { "enabled": true, "error": 200, "warning": 120 },
"closureBodyLength": { "enabled": true, "error": 50, "warning": 30 },
"functionBodyLength": { "enabled": true, "error": 100, "warning": 50 },
"associatedValueCount": { "enabled": true, "error": 6, "warning": 5 },
```

## Scope (rules affected)

- typeBodyLength
- lineLengthLimit
- closureBodyLength
- functionBodyLength
- associatedValueCount
- (audit for any other dual-threshold rules)

## Tasks

- [ ] Identify all dual-threshold lint-only rules
- [ ] Update rule configuration structs to use `enabled: Bool` instead of `lint` severity
- [ ] Update schema generation so `schema.json` reflects the new shape
- [ ] Update `swiftiomatic.json` and any sample/default configs
- [ ] Update tests that exercise these rules' configuration
- [ ] Update docs that describe configuring these rules
- [ ] Regenerate generated files



## Shared protocol/base class

These dual-threshold rules all follow the same pattern: a configurable `warning` threshold, a configurable `error` threshold, an `enabled` flag, and optionally a few extra properties. They likely deserve a shared protocol or base class — e.g. `ThresholdLintRule` — that:

- declares `enabled: Bool`, `warning: Int`, `error: Int`
- centralizes the severity-from-threshold logic (value ≥ error → error finding; value ≥ warning → warning finding)
- drives schema generation so the schema shape (`{ enabled, warning, error, ... }`) is emitted uniformly
- lets individual rules add their own optional properties on top

Tasks to add:

- [ ] Design the shared protocol/base (`ThresholdLintRule` or similar)
- [ ] Migrate the affected rules onto it
- [ ] Make schema generation aware of the pattern so all such rules render consistently
