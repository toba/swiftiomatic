---
# jks-pj3
title: Unify all rule definitions under Sources/Swiftiomatic/Rules/
status: scrapped
type: feature
priority: normal
created_at: 2026-02-28T02:24:12Z
updated_at: 2026-02-28T02:53:54Z
sync:
    github:
        issue_number: "49"
        synced_at: "2026-03-01T01:01:40Z"
---

Move ALL rule definitions into `Sources/Swiftiomatic/Rules/`. The Format/, Lint/, and Suggest/ directories become pure orchestration — they decide what to do with rule output (JSON for agents, Xcode format, auto-fix files), but don't define rules.

## Tasks

- [ ] Create `Diagnostic` unified output type and adapters (Finding, StyleViolation, Formatter.Change → Diagnostic)
- [ ] Move suggest check files (13 checks + BaseCheck + Check + Finding) into Rules/Suggest/
- [ ] Move format rule files (138 rules) into Rules/Format/
- [ ] Enhance RuleCatalog with capabilities (canAutoFix, isCrossFile, requiresSourceKit)
- [ ] Wire all three commands to produce [Diagnostic] output
- [ ] Verify: swift build, swift test, list-rules, suggest/lint/format produce unified JSON

## Design

Three execution models stay as-is internally (token closures, AST visitors, SourceKit-enhanced walkers). Unified at the output boundary via `Diagnostic` type. `RuleCatalog` becomes the single registry with capability metadata. Maps to swift-review skill §1-§8 categories.

See plan: .claude/plans/jolly-giggling-llama.md
