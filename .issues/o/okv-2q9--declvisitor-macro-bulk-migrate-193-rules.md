---
# okv-2q9
title: '@DeclVisitor macro: bulk migrate 193 rules'
status: scrapped
type: task
priority: normal
created_at: 2026-04-26T17:49:19Z
updated_at: 2026-04-26T19:06:24Z
parent: lhe-lqu
blocked_by:
    - j5a-lnn
    - 0vr-yit
sync:
    github:
        issue_number: "451"
        synced_at: "2026-04-26T19:46:00Z"
---

Phase 3 of `lhe-lqu`. Bulk migration after the macro supports all three patterns. Blocked by `j5a-lnn` (Phase 1) and the Phase 2 task.

## Scope

- Survey all 193 rules with overrides; classify each as Pattern A / B / C / hand-written-stays. Output the survey table to this issue body.
- Migrate all classifiable rules to `@DeclVisitor(...)`. Expected: ~115 Pattern A, ~30 Pattern B, ~1 Pattern C, plus a long tail that stays hand-written (multi-helper chains).
- Prefer migrating in groups by directory (`Sources/SwiftiomaticKit/Rules/<group>/`) so PRs are reviewable.
- After every rule that *can* migrate has migrated, remove the legacy member-walk fallback from `RuleCollector` (`Sources/GeneratorKit/RuleCollector.swift:154-162`). Any remaining hand-written rules must already declare `@DeclVisitor` (with `style: .custom` or similar opt-out) so the collector still discovers them — alternative: keep the fallback for the small hand-written set.
- Run the full lint/format corpus diff before and after migration; finding output must be byte-identical.

## Done when

- xc-swift package test passes.
- Corpus diff shows no behavioral change.
- `RuleCollector` either has no member-walk fallback, or the fallback is documented as serving a small, named set of rules.
- Total visit-override line count reduced by the expected ~1,500–2,000 lines (verify with `Grep "override func visit" Sources/SwiftiomaticKit/Rules/`).

## Follow-up (optional)

Audit `Pipelines+Generated.swift`, `ConfigurationRegistry+Generated.swift`, `TokenStream+Generated.swift` for outputs that could move to macros. Migrate **only** if measurably more performant *and* more reliable than the current build-tool plugin. File as a separate issue if pursued.
