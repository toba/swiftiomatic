---
# ugx-hol
title: Refactor GeneratePaths to accept injected base paths
status: completed
type: task
priority: normal
created_at: 2026-04-19T17:31:45Z
updated_at: 2026-04-19T17:51:12Z
parent: rcc-z52
sync:
    github:
        issue_number: "354"
        synced_at: "2026-04-23T05:30:28Z"
---

`GeneratePaths.swift` uses `#filePath` to locate the source tree. Plugins receive paths via the plugin context API (`context.package.directory`, target source directories). Refactor to accept injected paths.

## Plan

Convert `GeneratePaths` from an enum with static `let` properties to a struct with instance properties, accepting a package root URL.

### Files to modify

- `Sources/GeneratorKit/GeneratePaths.swift` — main refactor
- `Sources/Generator/main.swift` — update to use new API
- `Tests/SwiftiomaticTests/Utilities/GeneratedFilesValidityTests.swift` — update to use new API

### Changes

1. Convert `GeneratePaths` from `enum` to `struct`
2. Add `init(packageRoot: URL)` that derives all paths from the injected root
3. Add `static let filePath = GeneratePaths(packageRoot: ...)` convenience using `#filePath` derivation (keeps backward compat for the standalone executable and tests)
4. Change all `static let` path properties to instance `let` properties
5. Update `main.swift`: use `GeneratePaths.filePath` (or construct with explicit root)
6. Update `GeneratedFilesValidityTests.swift`: same pattern

### Design notes

- The `#filePath` convenience stays as a static property so existing call sites just change from `GeneratePaths.rulesDirectory` to `GeneratePaths.filePath.rulesDirectory` (or a local `let paths = GeneratePaths.filePath`)
- Future plugin code will call `GeneratePaths(packageRoot: context.package.directoryURL)` directly
- No behavioral change — just structural refactor

### Checklist

- [x] Convert enum to struct with `init(packageRoot:)`
- [x] Add static `filePath` convenience
- [x] Update Generator/main.swift
- [x] Update GeneratedFilesValidityTests.swift
- [x] Build passes
