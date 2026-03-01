---
# ref-vis
title: Remove dead Configuration+Remote remote config support
status: completed
type: task
priority: normal
created_at: 2026-02-28T19:14:14Z
updated_at: 2026-02-28T19:17:16Z
sync:
    github:
        issue_number: "63"
        synced_at: "2026-03-01T01:01:40Z"
---

Remove `Configuration+Remote.swift` — a SwiftLint leftover that downloads YAML config from URLs with local caching. Swiftiomatic is a local CLI tool with no remote config use case.

## TODO

- [ ] Delete `Sources/Swiftiomatic/Configuration/Configuration+Remote.swift`
- [ ] Remove any references to `Configuration.FileGraph.FilePath.promised`, `remoteConfigTimeout`, `remoteConfigTimeoutIfCached`, `mockedNetworkResults`, `deleteGitignoreAndSwiftlintCache`
- [ ] Remove the `.promised` enum case from `FilePath` if it exists
- [ ] Clean up any dead code paths that only existed to support remote config
- [ ] Verify build succeeds


## Summary of Changes

- Deleted `Sources/Swiftiomatic/Configuration/Configuration+Remote.swift` (291 lines)
- Removed `.promised(urlString:)` case from `FilePath` enum
- Removed `originalRemoteString`, `originatesFromRemote` from `Vertex`
- Removed `resolve()` method and all remote config timeout plumbing from `FileGraph`
- Removed `remoteConfigTimeout` / `remoteConfigTimeoutIfCached` keys from `Configuration.Key`
- Removed `mockedNetworkResults` parameter and cleanup logic from `Configuration.init`
- Simplified `findPossiblyExistingVertex` (no longer checks `originalRemoteString`)
- Removed guard against remote→local config references (no longer applicable)
