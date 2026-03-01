---
# gd2-ul1
title: 'Phase 1: Upgrade dependencies & fix breakage'
status: completed
type: task
priority: normal
created_at: 2026-02-27T23:03:32Z
updated_at: 2026-02-27T23:05:14Z
parent: 7ls-zus
sync:
    github:
        issue_number: "79"
        synced_at: "2026-03-01T01:01:45Z"
---

- [x] Update Package.swift: swift-syntax → 604, Yams → 6, SourceKitten → 0.37
- [x] Add new deps (deferred to Phase 2): CollectionConcurrencyKit, CryptoSwift, SwiftyTextTable, swift-filename-matcher
- [x] Fix any API breakage (none needed) in Analysis checks
- [x] Fix Config.swift (none needed) for Yams 6
- [x] Verify swift build passes passes
