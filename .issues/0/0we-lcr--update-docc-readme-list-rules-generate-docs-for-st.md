---
# 0we-lcr
title: Update DocC, README, list-rules / generate-docs for style model
status: completed
type: task
priority: normal
created_at: 2026-04-28T01:41:46Z
updated_at: 2026-04-30T00:11:11Z
parent: iv7-r5g
blocked_by:
    - ddi-wtv
sync:
    github:
        issue_number: "483"
        synced_at: "2026-04-30T00:29:45Z"
---

## Goal

Bring user-facing documentation and generator commands in line with the style-driven model from epic `iv7-r5g`.

## Tasks

- [x] README: replace any rule-toggle examples with style-based configuration. Document `compact` as the only supported style, `roomy` as reserved.
- [x] DocC: no Documentation.docc catalog exists for `SwiftiomaticKit`; updated the directory README instead (style overview, current Stage 1 / Structural / Pretty-print pipeline).
- [x] `sm list-rules` — already removed from `SwiftiomaticCommand` subcommands. Stale README references purged.
- [x] `sm generate-docs` — already removed from CLI; deleted dead `Sources/GeneratorKit/DocumentationGenerator.swift` (no remaining call site).

## Verification

- README renders correctly; example configs are valid against the new schema.
- `xc-swift swift_diagnostics` clean.
- DocC build succeeds with no broken links.


## Summary of Changes

- `README.md` rewritten around the style-driven config model. Now documents `style: "compact"` (default) and `style: "roomy"` (reserved), the `--style` CLI flag, the actual subcommand list, and the universal layout settings.
- `Sources/Swiftiomatic/README.md` subcommand table corrected: drops phantom `sm analyze`, `sm list-rules`, `sm generate-docs`; adds the actual `sm doctor`, `sm link`, `sm update`. Notes `--style` override on `format` / `lint` / `dump-configuration`.
- `Sources/SwiftiomaticKit/README.md` rewritten to match the real directory layout (`Configuration/`, `Extensions/`, `Findings/`, `Generated/`, `Layout/`, `Rewrites/`, `Rules/`, `Support/`, `Syntax/`) and the style-driven two-stage pipeline (`CompactStageOneRewriter` + ≤9 `StructuralFormatRule` passes + pretty-print).
- `Sources/GeneratorKit/README.md` updated: drops the `RuleDocumentationGenerator` row, lists the actual current generators, and updates the file-level descriptions.
- `Sources/GeneratorKit/DocumentationGenerator.swift` deleted (was the dead emitter for the removed `sm generate-docs`; no remaining call site).
- `CLAUDE.md` brought into sync: CLI section reflects the real subcommands; Rule Model section describes the three current base classes (`LintSyntaxRule`, `StaticFormatRule<V>`, `StructuralFormatRule`) and the two-stage format pipeline; Code Generation section names the four files actually emitted today (including `CompactStageOneRewriter+Generated.swift`); architecture bullet on configuration shape updated to style-driven format + per-rule lint.

### Verification

- `xc-swift swift_diagnostics --no-include-lint` (build_tests false): build succeeded, 11 warnings (no new diagnostics; matches baseline).
