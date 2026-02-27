---
# dl2-1pu
title: Upgrade dependencies for SwiftLint vendoring
status: scrapped
type: task
priority: normal
created_at: 2026-02-27T22:59:25Z
updated_at: 2026-02-27T23:33:06Z
parent: 5nn-red
---

Update Package.swift dependencies to match SwiftLint 0.63.2:
- swift-syntax: 601.0.1 → 604.0.0-prerelease-2026-01-20
- Yams: 5.0.0+ → 6.0.2+
- SourceKitten: 0.35.0+ → 0.37.2+

- [ ] Update Package.swift dependency versions
- [ ] Fix Analysis checks for swift-syntax 604 API changes
- [ ] Fix Config.swift for Yams 6 API changes
- [ ] Fix SourceKitService for SourceKitten 0.37 changes
- [ ] swift build passes
- [ ] swift test passes
