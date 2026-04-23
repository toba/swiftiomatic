---
# m3e-z21
title: Eliminate magic strings from Configuration
status: completed
type: task
priority: normal
created_at: 2026-04-18T22:12:26Z
updated_at: 2026-04-18T22:32:08Z
sync:
    github:
        issue_number: "342"
        synced_at: "2026-04-23T05:30:24Z"
---

- [x] Phase 1: Add Configurable conformance to rule config structs, update callers
- [x] Phase 2: Rename RuleCollector → ConfigurableCollector, unify generation
- [x] Phase 3: Simplify Context — remove ruleNameCache threading
- [x] Phase 4: Run generator and build


## Summary of Changes

- Rule config structs conform to `Configurable` — no magic strings
- `RuleCollector` → `ConfigurableCollector`, scans rules + layout settings
- `RuleNameCacheGenerator` merged into `RuleRegistryGenerator`
- `LayoutSettings.all` now delegates to generated `RuleRegistry.allSettingTypes`
- `Context` no longer threads `ruleNameCache` — uses `RuleRegistry.ruleNameCache` directly
- All tests pass
