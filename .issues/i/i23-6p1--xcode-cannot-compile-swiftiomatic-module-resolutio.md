---
# i23-6p1
title: Xcode cannot compile swiftiomatic — module resolution failure
status: completed
type: bug
priority: high
created_at: 2026-04-11T16:29:38Z
updated_at: 2026-04-11T16:39:21Z
sync:
    github:
        issue_number: "173"
        synced_at: "2026-04-11T16:40:44Z"
---

## Problem

Compiling the `swiftiomatic` scheme in Xcode fails. The `Swiftiomatic` library module never compiles successfully, causing cascading errors in `SwiftiomaticCLI`.

The key symptom: Xcode's emit-module step for the `Swiftiomatic` library target compiles the **wrong source files** — it uses `Sources/SwiftiomaticCLI/` files instead of `Sources/Swiftiomatic/` files, producing warnings like:

```
file 'FormatCommand.swift' is part of module 'Swiftiomatic'; ignoring import
```

The `Package.swift` is correctly structured with separate targets and default source paths. `swift package` commands from CLI may work fine — this appears to be an Xcode-specific issue with how SPM generates/caches its workspace.

## Things Tried (All Failed)

- [ ] **Delete `.swiftpm/xcode/` and DerivedData** — Cleared both, reopened in Xcode. Module confusion errors went away but replaced with `unable to open dependencies file` error. Not yet resolved.
- [ ] **Clean Folder (Shift+Cmd+K)** — Attempted after DerivedData wipe, awaiting result.
- [ ] ~~Case-insensitive filesystem theory~~ — Hypothesized that `swiftiomatic` (executable product) and `Swiftiomatic` (library target) collide on case-insensitive APFS. **Rejected** — filesystem is case-sensitive.
- [ ] Previous session: agent suggested various fixes (all wrong, details unknown)

## Log Evidence

First log (`2026-04-11T10-18-42`):
- `Swiftiomatic` target emit-module command lists only CLI files with `-module-name Swiftiomatic`
- `swiftiomatic.swiftmodule` and `Swiftiomatic.swiftmodule` both fail to generate
- All errors in `SwiftiomaticCLI` are "cannot find type" cascading from missing module

Second log (`2026-04-11T10-26-36`):
- After clearing `.swiftpm/xcode/` and DerivedData
- Module confusion errors gone
- New error: `unable to open dependencies file (.../FormatCommand.d)`

## Key Question

Why does Xcode's SPM integration assign `SwiftiomaticCLI/` source files to the `Swiftiomatic` library target? The `Package.swift` has no explicit `path:` so defaults should be unambiguous.

## Package.swift Target Structure

```swift
.target(name: "Swiftiomatic", ...)          // Sources/Swiftiomatic/
.executableTarget(name: "SwiftiomaticCLI")  // Sources/SwiftiomaticCLI/
// executable product name: "swiftiomatic" (lowercase)
```


## Resolution

**Root cause**: macOS APFS is case-insensitive by default. The executable product name `swiftiomatic` and library target name `Swiftiomatic` produced build directories (`swiftiomatic.build` vs `Swiftiomatic.build`) that resolved to the same path, causing Xcode to mix source files between targets.

**Fix**: Renamed the library target from `Swiftiomatic` to `SwiftiomaticKit` (and product from `SwiftiomaticLib` to `SwiftiomaticKit`). Updated 175 Swift files, the Xcode project, and the source directory name. The executable product remains `swiftiomatic` (the CLI tool name).

Confirmed: filesystem case-insensitivity verified with `touch aaa && ls AAA` test.
