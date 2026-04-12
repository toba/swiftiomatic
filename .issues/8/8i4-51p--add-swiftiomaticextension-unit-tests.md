---
# 8i4-51p
title: Add SwiftiomaticExtension unit tests
status: ready
type: task
priority: normal
created_at: 2026-04-12T15:57:34Z
updated_at: 2026-04-12T15:57:34Z
sync:
    github:
        issue_number: "222"
        synced_at: "2026-04-12T16:02:57Z"
---

The SwiftiomaticExtension Xcode target has zero test coverage. There is no test target in the Xcode project for the extension.

## Source files needing coverage

Located in `Xcode/SwiftiomaticExtension/`:

### Core logic (highest priority)
- `ConfigurationLoading.swift` — loads config from app group shared defaults
- `FormatFileCommand.swift` — formats entire file via source editor command
- `FormatSelectionCommand.swift` — formats selected text range
- `LintFileCommand.swift` — lints file and reports diagnostics
- `XCSourceTextBuffer+Swiftiomatic.swift` — bridge between XCSourceTextBuffer and Swiftiomatic engine
- `SelectionSnapshot.swift` — captures and restores selection state around edits
- `FormatCommandError.swift` — error type for format commands

### Infrastructure
- `SourceEditorExtension.swift` — extension entry point, command definitions
- `SharedDefaults.swift` — app group UserDefaults (shared with SwiftiomaticApp)

## Requirements

- [ ] Create an Xcode test target (`SwiftiomaticExtensionTests`) in `Xcode/Swiftiomatic.xcodeproj`
- [ ] Add the test target to the Swiftiomatic scheme's Testables
- [ ] Write unit tests for config loading from shared defaults
- [ ] Write unit tests for `SelectionSnapshot` capture/restore logic
- [ ] Write unit tests for `XCSourceTextBuffer` extension methods
- [ ] Write unit tests for format/lint command logic (may need mock `XCSourceTextBuffer`)

## Notes

- Use Swift Testing (`import Testing`, `@Test`, `#expect`) — not XCTest
- XCSourceEditorExtension commands receive an `XCSourceEditorCommandInvocation` — testing may require mocking or extracting testable logic into pure functions
- The extension shares `SharedDefaults` with the app — config round-trip tests can be shared
