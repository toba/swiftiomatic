---
# wvs-pwa
title: Baseline system for incremental adoption
status: scrapped
type: feature
priority: critical
created_at: 2026-04-10T22:25:29Z
updated_at: 2026-04-11T21:31:48Z
parent: pms-xpz
sync:
    github:
        issue_number: "163"
        synced_at: "2026-04-11T22:00:31Z"
---

Allow teams to adopt Swiftiomatic on large codebases without fixing every pre-existing violation first.

```bash
# Generate baseline from current violations
swiftiomatic analyze Sources/ --save-baseline .swiftiomatic-baseline.json

# Future runs ignore baselined violations
swiftiomatic analyze Sources/ --baseline .swiftiomatic-baseline.json
```

The baseline file records (ruleID, file, line-content-hash) tuples. Violations matching a baseline entry are suppressed. When the offending line changes, the violation resurfaces.

## Tasks

- [ ] Define baseline file format (JSON with content hashes, not line numbers)
- [ ] Implement `--save-baseline <path>` flag on analyze/lint commands
- [ ] Implement `--baseline <path>` flag to load and filter against baseline
- [ ] Use content hashing so moved-but-unchanged code stays suppressed
- [ ] Implement `--update-baseline` to prune fixed violations from baseline
- [ ] Report count of baselined (suppressed) violations in summary output
- [ ] Add tests for baseline generation, filtering, and pruning
- [ ] Document baseline workflow
