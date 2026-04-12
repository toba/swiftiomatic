---
# 8i4-51p
title: Add SwiftiomaticExtension unit tests
status: scrapped
type: task
priority: normal
created_at: 2026-04-12T15:57:34Z
updated_at: 2026-04-12T16:11:50Z
sync:
    github:
        issue_number: "222"
        synced_at: "2026-04-12T16:28:28Z"
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

- [ ] ~~Create an Xcode test target (`SwiftiomaticExtensionTests`) in `Xcode/Swiftiomatic.xcodeproj`~~
- [ ] ~~Add the test target to the Swiftiomatic scheme's Testables~~
- [ ] ~~Write unit tests for config loading from shared defaults~~
- [ ] ~~Write unit tests for `SelectionSnapshot` capture/restore logic~~
- [ ] ~~Write unit tests for `XCSourceTextBuffer` extension methods~~
- [ ] ~~Write unit tests for format/lint command logic (may need mock `XCSourceTextBuffer`)~~

## Notes

- Use Swift Testing (`import Testing`, `@Test`, `#expect`) — not XCTest
- XCSourceEditorExtension commands receive an `XCSourceEditorCommandInvocation` — testing may require mocking or extracting testable logic into pure functions
- The extension shares `SharedDefaults` with the app — config round-trip tests can be shared


## Reasons for Scrapping

The SwiftiomaticExtension is a thin adapter layer (~150 lines across 8 files) that bridges XcodeKit's `XCSourceTextBuffer` API to SwiftiomaticKit's `format()`/`lint()` public API. After reviewing every source file:

1. **Commands are trivial glue** — each reads a buffer, calls one SwiftiomaticKit function, writes the result back. The real logic (formatting, linting, configuration parsing) already has extensive test coverage in SwiftiomaticKit.
2. **XcodeKit types can't be instantiated in tests** — `XCSourceEditorCommandInvocation` and `XCSourceTextBuffer` have no public initializers. Apple's own guidance is to extract pure functions and test those, but there are no pure functions worth extracting here.
3. **Remaining "logic" is trivial** — `min()` for selection clamping, `Set.contains()` for UTI checking, a ternary for indentation detection, static string constants. Testing these would be asserting stdlib behavior.
4. **Config loading** is a 5-line guard that calls `Configuration.fromYAMLString()` — already tested in SwiftiomaticKit.

Writing tests here would be test theater: high ceremony, zero meaningful coverage of actual risk.
