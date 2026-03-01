---
# vto-8r7
title: Extract library target + create Xcode Source Editor Extension
status: completed
type: feature
priority: normal
created_at: 2026-03-01T02:40:50Z
updated_at: 2026-03-01T06:45:23Z
sync:
    github:
        issue_number: "112"
        synced_at: "2026-03-01T06:46:19Z"
---

## Goal

Split the Swiftiomatic executable into a library + CLI target, then create an Xcode Source Editor Extension for Format File / Format Selection commands.

## Tasks

- [x] Step 1: Extract library target from executable
  - [x] Move swiftiomatic.swift and FormatCommand.swift to Sources/SwiftiomaticCLI/
  - [x] Update Package.swift: library + executable targets
  - [x] Add package access to all types referenced by SwiftiomaticCLI
  - [x] Fix compiler crash in RuleList.swift (key path on existential)
  - [x] Verify swift build passes (both targets)
  - [ ] Note: format tests have pre-existing crash in File.swift:36 (virtual file path force-unwrap)
- [x] Step 2: Create Xcode project with host app + Source Editor Extension
  - [x] Create Xcode/ directory structure and project.pbxproj
  - [x] Create minimal host app (LSUIElement, no UI)
  - [x] Create extension with FormatFileCommand and FormatSelectionCommand
  - [x] Configure Info.plist with extension declarations
  - [x] Link SwiftiomaticLib via local SPM package dependency
  - [x] Verify build in Xcode


## Summary of Changes

- Created Xcode project (`Xcode/Swiftiomatic.xcodeproj`) with xc-project MCP tools
- **SwiftiomaticApp** target: LSUIElement host app with no UI, exists solely to host the extension
- **SwiftiomaticExtension** target: Source Editor Extension with FormatFileCommand and FormatSelectionCommand
- Extension links SwiftiomaticLib (local SPM package) and XcodeKit framework
- Added `PublicAPI.swift` with `public enum Swiftiomatic` facade exposing `format()` to external consumers
- Fixed `ExpiringTodoRule.swift` module-qualified call that conflicted with the public enum
- Both Xcode and SPM builds pass
