---
# 4hc-acl
title: Remove unnecessary nonisolated(unsafe) annotations
status: completed
type: task
priority: normal
created_at: 2026-04-25T20:42:07Z
updated_at: 2026-04-25T21:03:40Z
parent: 0ra-lks
sync:
    github:
        issue_number: "433"
        synced_at: "2026-04-25T22:35:12Z"
---

**Note**: Original premise was wrong — `Regex` is **not** `Sendable` in Swift 6.3. The two regex-related findings are intentionally left as-is. The `/swift` skill (`~/.claude/skills/swift/SKILL.md` row 8g) was updated to call this out explicitly so future agents don't repeat the mistake. `CommandConfiguration` *is* `Sendable`, so those annotations were safely removed.

## Findings

- [ ] `Sources/ConfigurationKit/Configurable.swift:8` — left as `nonisolated(unsafe) let`. `Regex<Substring>` is not Sendable in Swift 6.3.
- [ ] `Sources/SwiftiomaticKit/Syntax/RuleMask.swift:143, 147` — left as `nonisolated(unsafe) let`. `Regex<...>` is not Sendable in Swift 6.3.
- [x] `Sources/Swiftiomatic/SwiftiomaticCommand.swift:19` — `nonisolated(unsafe) static var configuration` → `static let configuration`.
- [x] `Sources/Swiftiomatic/Subcommands/Doctor.swift:7`
- [x] `Sources/Swiftiomatic/Subcommands/DumpConfiguration.swift:22`
- [x] `Sources/Swiftiomatic/Subcommands/Format.swift:18`
- [x] `Sources/Swiftiomatic/Subcommands/Lint.swift:18`
- [x] `Sources/Swiftiomatic/Subcommands/Update.swift:7`

## Verification
- [x] Build clean.

## Summary of Changes

Removed the unnecessary `nonisolated(unsafe)` annotations on six `ParsableCommand.configuration` declarations (`SwiftiomaticCommand` + 5 subcommands). `CommandConfiguration` is `Sendable`, and `ParsableCommand`'s protocol requirement (`static var configuration: CommandConfiguration { get }`) is satisfied by `static let`, which is implicitly thread-safe — no annotation required.

Two regex-related findings deferred: `Regex` is **not** `Sendable` in Swift 6.3, so `nonisolated(unsafe) let` is still required for cached regex globals. Updated `~/.claude/skills/swift/SKILL.md` row 8g to make this explicit and prevent the same mistake in future code reviews.
