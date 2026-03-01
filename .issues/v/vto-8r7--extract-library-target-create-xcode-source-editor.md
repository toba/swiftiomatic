---
# vto-8r7
title: Extract library target + create Xcode Source Editor Extension
status: in-progress
type: feature
priority: normal
created_at: 2026-03-01T02:40:50Z
updated_at: 2026-03-01T03:51:01Z
sync:
    github:
        issue_number: "112"
        synced_at: "2026-03-01T03:57:23Z"
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
- [ ] Step 2: Create Xcode project with host app + Source Editor Extension
  - [ ] Create Xcode/ directory structure
  - [ ] Create minimal host app (LSUIElement, no UI)
  - [ ] Create extension with FormatFileCommand and FormatSelectionCommand
  - [ ] Configure Info.plist with extension declarations
  - [ ] Link SwiftiomaticLib product
  - [ ] Verify build in Xcode
