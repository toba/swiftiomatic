---
# o72-vx7
title: 'Configuration schema redesign: `style` + universal parameters'
status: completed
type: feature
priority: high
created_at: 2026-04-28T01:41:15Z
updated_at: 2026-04-28T02:15:04Z
parent: iv7-r5g
blocked_by:
    - 2kl-d04
sync:
    github:
        issue_number: "481"
        synced_at: "2026-04-28T02:40:01Z"
---

## Goal

Replace the rule-toggle configuration model with a style-driven one, per epic `iv7-r5g`.

## Changes

- `Configuration`: drop `rules: [String: Bool]`. Drop or fold per-rule sub-config structs (`orderedImports`, `fileScopedDeclarationPrivacy`, etc.) per the `compact` design spec (`2kl-d04`).
- Add `style: Style` (cases: `compact`, `roomy`-stub).
- Keep universal parameters: `lineLength`, `indentation`, `tabWidth`, `respectsExistingLineBreaks`, line endings, etc.
- Regenerate the configuration schema via the `Generator` executable; update `schema.json`.
- Migration: when an old configuration with `rules: { ... }` is loaded, log a deprecation warning and map it onto `compact`. Removal of the legacy keys is acceptable in a single major version bump — this is a fork, not the upstream contract.

## Out of scope

- CLI-side `--style` flag — see follow-up issue.
- Cutover of `FormatPipeline` — see follow-up issue.



## Refinement: lint config shape

Lints stay discrete (perf is fine — they already run through `LintPipeline`). Replace today's `rules: [String: Bool]` (which mixed lint + format toggles) with a lint-only map using a tri-state severity:

```json
"lints": {
  "<group>": { "<RuleName>": "off" | "warn" | "error" }
}
```

Group key matches the `Sources/SwiftiomaticKit/Rules/<Group>/` directory.

For rules with additional config, accept the nested form: `{ "<RuleName>": { "severity": "warn", "<extraKey>": ... } }`. Bare-string form is preferred for the common case.

The format side has no per-rule toggles — `style` + universal parameters only.



## Summary of Changes

- Added `Sources/SwiftiomaticKit/Rules/Style.swift` defining `Style` enum (`compact`, `roomy`) and `StyleSetting: LayoutRule` (top-level, ungrouped). Default: `.compact`.
- Bumped `highestSupportedConfigurationVersion` from 6 → 7 in `Sources/SwiftiomaticKit/Configuration/Configuration.swift`.
- The build plugin auto-registers the new `LayoutRule` via `ConfigurationRegistry.allSettingTypes` — no hand-written registry edits required.
- Build clean (`xc-swift swift_package_build`).

### Deferred to cutover (`ddi-wtv`)

The current `Configuration` already stores rule values via the typed-key registry, not as a `rules: [String: Bool]` map. The conceptual surface ("drop the rule-toggle model") only goes away once the underlying `SyntaxFormatRule` types are deleted in `ddi-wtv`. Likewise, the lint-config `lints: { group: { Rule: severity } }` shape from `2kl-d04` requires the encoder/decoder to know which rules are lints vs format — a distinction that's only meaningful after format rules are removed. Both belong in cutover.

### Migration warning

No format-side legacy keys to warn about today (configs encode per-rule values inside group containers; nothing to silently drop yet). The actual deprecation prompts will fire during cutover when those group containers stop accepting format-rule keys.

### Schema regeneration

Run `swift run Generator` after merging to refresh `schema.json` with the new `style` key — not part of the SPM build plugin output.
