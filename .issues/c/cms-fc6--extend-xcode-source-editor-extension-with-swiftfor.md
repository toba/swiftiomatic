---
# cms-fc6
title: Extend Xcode Source Editor Extension with SwiftFormat-inspired features
status: in-progress
type: feature
priority: normal
created_at: 2026-03-01T17:48:45Z
updated_at: 2026-03-01T18:03:11Z
sync:
    github:
        issue_number: "123"
        synced_at: "2026-03-01T18:21:06Z"
---

## Context

The Swiftiomatic Xcode Source Editor Extension (under `Xcode/`) currently has minimal stub implementations. SwiftFormat's [EditorExtension](https://github.com/nicklockwood/SwiftFormat/tree/main/EditorExtension) provides a mature reference with features we should adopt, adapted to Swiftiomatic's AST-based rule engine and modernized for Swift 6.2.

### Current State

- **SourceEditorExtension.swift** — empty principal class
- **FormatFileCommand.swift** — basic format-entire-buffer, no content-type validation, no selection preservation, no early-exit on unchanged content
- **FormatSelectionCommand.swift** — basic range formatting, no content-type validation, naive line splitting
- **AppDelegate.swift** — empty LSUIElement host app
- **PublicAPI.swift** — single \`SwiftiomaticLib.format(_:)\` entry point

### What SwiftFormat Does Well (to adopt)

1. **Content-type validation** — checks \`SupportedContentUTIs\` before processing (Swift source, playgrounds, package manifests)
2. **Typed command errors** — \`FormatCommandError\` enum with \`LocalizedError\` + \`CustomNSError\` conformance for user-facing messages
3. **Selection preservation** — removes selections before buffer mutation to prevent Xcode crashes, restores at new positions using token-based offset calculation
4. **Lint File command** — surfaces lint warnings directly in the extension
5. **Buffer helper extension** — \`XCSourceTextBuffer+\` for indentation detection and position/offset conversion
6. **App group UserDefaults** — shared storage between host app and extension for rules/options
7. **Host app UI** — rules browser, options editor with table views for toggling rules on/off

## Tasks

- [ ] Add \`SupportedContentUTIs\` — array of UTIs the extension should handle (\`public.swift-source\`, \`com.apple.dt.playground\`, \`com.apple.dt.playgroundpage\`, \`com.apple.dt.swiftpm-package-manifest\`)
- [ ] Add \`FormatCommandError\` enum — \`.notSwiftLanguage\`, \`.noSelection\`, \`.invalidSelection\`, \`.lintWarnings([Diagnostic])\` with \`LocalizedError\` conformance. Use Swift 6.2 typed throws where applicable
- [ ] Add \`XCSourceTextBuffer+Swiftiomatic\` extension — content-type validation helper, indentation string detection, position/offset conversion
- [ ] Rewrite \`FormatFileCommand\` — validate content type, preserve/restore selections around buffer mutation, early-exit on no changes, proper error handling with \`FormatCommandError\`
- [ ] Rewrite \`FormatSelectionCommand\` — validate content type + selection exists, selection-aware formatting, restore selection at new positions
- [ ] Add \`LintFileCommand\` — new command that runs lint-scope rules and reports findings as a user-facing error summary. Register in Info.plist
- [ ] Expand \`PublicAPI.swift\` — add \`SwiftiomaticLib.lint(_:)\` returning diagnostics, so the extension can use it
- [ ] Update \`Info.plist\` — register \`LintFileCommand\` as third command (\`com.toba.swiftiomatic.extension.lint-file\`, "Lint File")
- [ ] Update \`SourceEditorExtension\` — implement \`extensionDidFinishLaunching()\` if needed for initialization
- [ ] Add App Group entitlements — shared \`UserDefaults\` suite for future settings sync between host app and extension
- [ ] All new code must be Swift 6.2 strict concurrency, \`Sendable\` where needed, no warnings

## Modernization Requirements (Swift 6.2 / swift-review)

- Use typed throws (\`throws(FormatCommandError)\`) where the error type is known
- Mark types \`@Sendable\` or conform to \`Sendable\` as needed for XPC extension context
- Prefer \`sending\` parameter annotations if passing data across isolation boundaries
- Use \`nonisolated(unsafe)\` only as a last resort — prefer proper sendability
- No \`@objc\` unless required by XcodeKit protocol conformance
- Use \`if let\`/\`guard let\` shorthand (no redundant \`= variable\`)
- Prefer \`for-in\` with indices over manual counter loops

## Non-Goals (for now)

- Host app UI for toggling rules/options (future task)
- App group UserDefaults stores (future task — depends on host app UI)
- Storyboard / SwiftUI settings interface
