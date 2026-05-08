---
# ae4-quf
title: 'sm format strips ''#if false ... #endif'' compilation guards, exposing intentionally-disabled code to the compiler'
status: completed
type: bug
priority: high
created_at: 2026-05-08T22:14:59Z
updated_at: 2026-05-08T22:19:00Z
sync:
    github:
        issue_number: "672"
        synced_at: "2026-05-08T22:24:57Z"
---

## Summary

`sm format` removes `#if false` / `#endif` blocks (and their accompanying `// FIXME:` comment, if present), exposing the previously-disabled body to the compiler. In the Thesis tree this stripped guards from 11 test files in a single pass, producing >70 build errors.

## Example

`Core/Tests/Support/MockSyncEngine.swift` (HEAD):
```swift
// FIXME: Disabled pending structured queries API migration fixes
#if false
@testable import Core
import CloudKit
// ... ~140 lines of test code referencing types that no longer exist ...
#endif
```

After `sm format`:
```swift
@testable import Core
import CloudKit
// ... ~140 lines, no longer guarded ...
```

The body references `SyncEngineStateProtocol`, `SyncEngineProtocol`, and other symbols that were intentionally removed during a structured-queries API migration. The `#if false` was placed precisely to keep these files in-tree (preserving git history, line-level review of future fixes) while skipping compilation. Stripping the guard reintroduces ~70 compile errors all at once.

## Affected files in the Thesis tree (single sm-format run)

- `Core/Tests/Citation/BibliographyTests.swift`
- `Core/Tests/Citation/CitationGroupTests.swift`
- `Core/Tests/Citation/CitationTests.swift`
- `Core/Tests/Citation/CitedReferenceTests.swift`
- `Core/Tests/Citation/ReferenceSelectionTests.swift`
- `Core/Tests/Citation/ReferenceTests.swift`
- `Core/Tests/Support/MockSyncEngine.swift`
- `Core/Tests/SyncMetadataTests.swift`
- `Core/Tests/SyncTriggerTests.swift`
- `Core/Tests/SynchronizedTableAssetTests.swift`
- `Core/Tests/WordCountTests.swift`

## Hypothesis

Likely the dead-code-elimination or `flagAlwaysFalse` rule treats `#if false` as "obviously dead" and removes it. But `#if false` has a recognized idiom for *temporarily* parking code: the contents are not intended to be compiled, but the file is intended to be tracked.

## Suggested fix

Treat `#if false` (and `#if 0`, by analogy with C) as a load-bearing compilation guard, not as dead code to remove. Either:

1. Never strip `#if`/`#endif` blocks in the formatter — that's a semantic change, not a formatting change.
2. If a redundancy rule must exist, gate it behind opt-in and emit a warning that points to the FIXME / TODO comment so the user can decide.

## Severity

High. Every stripped guard exposes code that was intentionally removed from compilation, often producing 5–20 compile errors per file. Users won't realize what happened until they run a build.



## Reasons for Scrapping

False positive on my part. The Thesis maintainer clarified that another agent was intentionally removing the `#if false` wrappers as part of migrating the disabled tests. The unwrapping was deliberate, not `sm format` damage. No bug here.
