---
# auz-78x
title: Remove FileGraph wrapper struct, inline rootDirectory into Configuration
status: completed
type: task
priority: normal
created_at: 2026-02-28T22:35:36Z
updated_at: 2026-02-28T22:43:51Z
---

FileGraph was gutted to just `struct FileGraph: Hashable { let rootDirectory: String }` — a pointless wrapper. Inline it.

- [x] Move `resultingConfiguration` static method from FileGraph into Configuration as private static
- [x] Delete `Configuration+FileGraph.swift`
- [x] Replace `var fileGraph: FileGraph` with `var rootDirectory: String` on Configuration
- [x] Update all inits to use `rootDirectory: String` instead of `fileGraph: FileGraph`
- [x] Update Hashable/Equatable to use rootDirectory directly
- [x] Update init(copying:) 
- [x] Remove the computed `rootDirectory` property (now it's stored directly)
- [x] Build to verify


## Summary of Changes

Removed the `FileGraph` wrapper struct entirely. Its only remaining field (`rootDirectory: String`) is now stored directly on `Configuration`. The `resultingConfiguration` static method moved into `Configuration` as a private static method. Deleted `Configuration+FileGraph.swift`.
