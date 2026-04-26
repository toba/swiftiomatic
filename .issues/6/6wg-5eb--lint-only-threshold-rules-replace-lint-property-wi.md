---
# 6wg-5eb
title: 'Lint-only threshold rules: replace ''lint'' property with ''enabled'''
status: review
type: bug
priority: normal
created_at: 2026-04-26T17:56:51Z
updated_at: 2026-04-26T18:17:30Z
sync:
    github:
        issue_number: "447"
        synced_at: "2026-04-26T18:19:14Z"
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

- [x] Identify all dual-threshold lint-only rules
- [x] Update rule configuration structs to use `enabled: Bool` instead of `lint` severity
- [x] Update schema generation so `schema.json` reflects the new shape
- [ ] Update default project configuration to use `enabled` (blocked by jig hook — user must edit)
- [x] Update tests (existing tests unaffected — they set `warning`/`error` directly)
- [x] Update docs (no rule docs referenced the `lint` field for these rules)
- [x] Regenerate generated files (schema.json + ConfigurationSchema+Generated.swift)



## Shared protocol/base class

These dual-threshold rules all follow the same pattern: a configurable `warning` threshold, a configurable `error` threshold, an `enabled` flag, and optionally a few extra properties. They likely deserve a shared protocol or base class — e.g. `ThresholdLintRule` — that:

- declares `enabled: Bool`, `warning: Int`, `error: Int`
- centralizes the severity-from-threshold logic (value ≥ error → error finding; value ≥ warning → warning finding)
- drives schema generation so the schema shape (`{ enabled, warning, error, ... }`) is emitted uniformly
- lets individual rules add their own optional properties on top

Tasks to add:

- [x] Design the shared protocol/base — landed as `ThresholdRuleValue` in ConfigurationKit
- [x] Migrate the 9 affected rules onto it
- [x] Schema generator emits `thresholdLintBase` `$def` and the 9 rules `$ref` it



## Summary of Changes

- New `ThresholdRuleValue` protocol in `Sources/ConfigurationKit/ThresholdRuleValue.swift`. Refines `SyntaxRuleValue`; declares `enabled`, `warning`, `error`. Synthesizes `lint`/`rewrite` bridges so existing pipeline code (`Context.severity`, `disable`/`enable`, `isActive`) keeps working unchanged.
- 9 metrics rule configurations migrated: `TypeBodyLength`, `LineLengthLimit`, `ClosureBodyLength`, `FunctionBodyLength`, `AssociatedValueCount`, `CyclomaticComplexity`, `ParameterCount`, `FileLength`, `TupleSize`. Each replaces `var lint: Lint` with `var enabled: Bool` and the synthesized `rewrite` shim.
- `RuleCollector`: new `isThreshold` field on `DetectedSyntaxRule`; new `structConforms(_:to:in:)` helper; `extractCustomProperties` skips `enabled`/`warning`/`error` when the config is a threshold rule.
- `ConfigurationSchemaGenerator`: new `thresholdLintBase` `$def` (`enabled`/`warning`/`error`); `ruleSchemaNode` picks the new `$ref` for threshold rules.
- Generated artifacts regenerated: `schema.json`, `ConfigurationSchema+Generated.swift`, `.generator-fingerprint`.
- Build green; full test suite green (2951/2951).

### User action required (review status)

The project's default configuration file at the repo root still contains `"lint": "warn"` for the 9 affected rules. Decoding silently ignores those keys, so runtime is fine, but the regenerated schema's `unevaluatedProperties: false` will flag them as invalid in IDE schema validation. Update the 9 entries to the new shape, e.g.:

```jsonc
"typeBodyLength":      { "enabled": true, "error": 350, "warning": 250 },
"lineLengthLimit":     { "enabled": true, "error": 200, "warning": 120 },
"closureBodyLength":   { "enabled": true, "error":  50, "warning":  30 },
"functionBodyLength":  { "enabled": true, "error": 100, "warning":  50 },
"associatedValueCount":{ "enabled": true, "error":   6, "warning":   5 },
"cyclomaticComplexity":{ "enabled": true, "error":  20, "warning":  10, "ignoresCaseStatements": false },
"parameterCount":      { "enabled": true, "error":   8, "warning":   5, "ignoresDefaultParameters": true },
"fileLength":          { "enabled": true, "error": 1000, "warning": 400, "ignoreCommentOnlyLines": true },
"tupleSize":           { "enabled": true, "error":   4, "warning":   3 }
```

(`nestingDepth` is not a threshold rule — it has `typeLevel`/`functionLevel` instead — so it stays as-is.)
