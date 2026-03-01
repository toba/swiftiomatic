---
# bpt-2qz
title: Vendor SwiftLint 0.63.2 source
status: scrapped
type: task
priority: normal
created_at: 2026-02-27T22:59:25Z
updated_at: 2026-02-27T23:33:06Z
parent: 5nn-red
blocked_by:
    - dl2-1pu
sync:
    github:
        issue_number: "77"
        synced_at: "2026-03-01T01:01:44Z"
---

Clone SwiftLint 0.63.2 and vendor Core + BuiltInRules into Sources/SwiftLintVendored/.

- [ ] Clone SwiftLint 0.63.2
- [ ] Copy SwiftLintCore → Sources/SwiftLintVendored/Core/
- [ ] Copy SwiftLintBuiltInRules → Sources/SwiftLintVendored/BuiltInRules/
- [ ] Add new deps: CollectionConcurrencyKit, CryptoSwift, SwiftyTextTable, swift-filename-matcher
- [ ] Add SwiftLintVendored target to Package.swift with .swiftLanguageMode(.v5)
- [ ] Strip CLI, plugins, test helpers, macros
- [ ] Collapse #if canImport version conditionals to 604-only
- [ ] swift build passes
