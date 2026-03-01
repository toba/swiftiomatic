---
# v1g-3vl
title: Initialize SPM package with swift-syntax dependency
status: completed
type: task
priority: normal
created_at: 2026-02-27T21:32:15Z
updated_at: 2026-02-27T21:44:12Z
parent: 52u-0w0
sync:
    github:
        issue_number: "106"
        synced_at: "2026-03-01T01:41:14Z"
---

Set up the Swift package skeleton.

- [ ] `swift package init --type executable --name swiftiomatic`
- [ ] Add dependencies to Package.swift:
  - `swift-syntax` 601.0.1+ (SwiftSyntax, SwiftParser, SwiftSyntaxBuilder)
  - `swift-argument-parser` 1.5+ (ArgumentParser)
- [ ] Create directory structure: `Sources/{Swiftiomatic,Analysis,Checks,Output}`, `Tests/SwiftiomaticTests/Fixtures`
- [ ] Set Swift language version to 6.0 with strict concurrency
- [ ] Set platforms to `.macOS(.v15)`
- [ ] Verify `swift build` succeeds with empty sources
- [ ] Add `.swiftformat` config (project already has `.swiftlint.yml`)

swift-syntax version must match the toolchain. For Xcode 26.2 (Swift 6.2), use swift-syntax 601.0.1 or the matching tag from `swiftlang/swift-syntax`.

## Summary of Changes
- Initialized SPM package with swift-syntax 601.0.1+ and swift-argument-parser 1.5+
- Created directory structure: Sources/{Swiftiomatic,Analysis/{Checks,Output}}, Tests/SwiftiomaticTests/Fixtures
- Set platforms to macOS 15+, Swift language mode v6
- Verified swift build succeeds
