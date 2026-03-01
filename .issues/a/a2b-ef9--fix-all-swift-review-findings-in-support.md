---
# a2b-ef9
title: Fix all swift-review findings in Support/
status: completed
type: task
priority: normal
created_at: 2026-03-01T04:34:45Z
updated_at: 2026-03-01T04:39:53Z
sync:
    github:
        issue_number: "116"
        synced_at: "2026-03-01T04:54:05Z"
---

Fix all issues found by swift-review in Sources/Swiftiomatic/Support/:

- [x] 1a. Extract shared processTrivia logic into TriviaLineCollector, refactor both visitors
- [x] 2a. Delete EnumAssociable.swift (dead code — associatedValue() never called), remove conformance from ArgumentType
- [x] 3a. Add typed throws(Issue) to YamlParser.parse
- [x] 4a. Remove @unchecked Sendable from TaskFinder
- [x] 6c. Precompute mutatingPrefixes in MutationDuringIterationFinder.init
- [x] 7a. Rename shallSkip to shouldSkip in ViolationCollectingVisitor
- [x] 7b. Change modifyLast(by:) to modifyLast(using:)
- [x] 7c. Add CustomStringConvertible to EnclosingScope
- [x] 8b. Delete CacheDescriptionProvider.swift (dead — no conformers), simplify Rule.cacheDescription

## Summary of Changes

### Files modified
- **Stack.swift** — renamed `modifyLast(by:)` to `modifyLast(using:)`
- **ViolationCollectingVisitor.swift** — renamed `shallSkip` to `shouldSkip`
- **TaskPatternDetector.swift** — removed `@unchecked Sendable` from TaskFinder, added `CustomStringConvertible` to EnclosingScope
- **YamlParser.swift** — added typed `throws(Issue)`
- **MutationDuringIterationFinder.swift** — precompute `mutatingPrefixes` in init
- **CommentLinesVisitor.swift** — refactored to use TriviaLineCollector
- **EmptyLinesVisitor.swift** — refactored to use TriviaLineCollector
- **OptionDescriptor.swift** — removed dead EnumAssociable conformance
- **Rule.swift** — simplified cacheDescription (removed dead CacheDescriptionProvider cast)

### Files created
- **TriviaLineCollector.swift** — shared trivia line extraction logic

### Files deleted
- **EnumAssociable.swift** — dead code (no callers of associatedValue())
- **CacheDescriptionProvider.swift** — dead code (no conformers)
