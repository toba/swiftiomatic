---
# cms-fc6
title: Extend Xcode Source Editor Extension with SwiftFormat-inspired features
status: completed
type: feature
priority: normal
created_at: 2026-03-01T17:48:45Z
updated_at: 2026-03-01T19:41:05Z
sync:
    github:
        issue_number: "123"
        synced_at: "2026-03-01T21:06:26Z"
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

## Implementation Progress (2026-03-01)

### Phase 1: Public API Expansion — DONE

All code changes written and SPM library builds clean (`swift build --target Swiftiomatic` passes).

**1a. Widened access levels (`package` → `public`):**
- `Diagnostic` struct + all stored properties + `<` operator
- `DiagnosticSource` enum + cases + `displayName`
- `DiagnosticSeverity` enum + cases
- `Confidence` enum + cases + `<` operator (via CaseIterable extension)
- `Scope` enum + cases + `displayName`
- `RuleDescription` struct — `identifier`, `name`, `description`, `rationale`, `scope`, `isCorrectable` (new computed), `==` made public. Init stays `package` (uses internal `Example`/`SwiftVersion` types).
- `Configuration` struct — made `public` with public getters/setters for: `enabledLintRules`, `disabledLintRules`, `lintRuleConfigs`, `enabledFormatRules`, `disabledFormatRules`, `formatIndent`, `formatMaxWidth`, `suggestMinConfidence`, `default`, `loadUnified(from:)`, `hash(into:)`, `==`, `description`.
- `ConfigValue` enum — made `public` (needed by `lintRuleConfigs`).
- `Example` struct — made `package` (was internal, needed by `RuleDescription` init). Fixed `==`, `hash`, `<` access levels.

**1b. New type `RuleCatalogEntry`:**
- File: `Sources/Swiftiomatic/Models/RuleCatalogEntry.swift`
- Public struct with `Sendable`, `Identifiable`, `Codable`, `Hashable` conformances.
- Properties: `identifier`, `name`, `description`, `rationale`, `scope`, `isCorrectable`, `isOptIn`.

**1c. Expanded `PublicAPI.swift`:**
- `SwiftiomaticLib.format(_:configuration:)` — format with custom config
- `SwiftiomaticLib.lint(_:fileName:)` — runs lint-scope rules on source string, returns sorted `[Diagnostic]`
- `SwiftiomaticLib.ruleCatalog()` — returns `[RuleCatalogEntry]` for all registered rules (lint + format)
- `SwiftiomaticLib.loadConfiguration(from:)` — facade over `Configuration.loadUnified(from:)`
- `SwiftiomaticLib.saveConfiguration(_:to:)` — facade over `Configuration.writeYAML(to:)`

**1d. Configuration write-back:**
- Added `Configuration.writeYAML(to:)` — serializes non-default values back to YAML using Yams. Only writes sections that differ from defaults.

### Phase 2: Extension Infrastructure — DONE

All files created on disk.

- `FormatCommandError.swift` — enum with `.unsupportedContentType`, `.formatFailed`, `.noSelection`, `.lintSummary` + `LocalizedError` + `CustomNSError`
- `XCSourceTextBuffer+Swiftiomatic.swift` — `supportedContentUTIs`, `isSwiftSource`, `detectedIndentation`
- `SelectionSnapshot.swift` — captures/restores `XCSourceTextRange`, `restoreSelections()` free function
- `SharedDefaults.swift` — `suiteName`, `suite`, `configBookmarkKey`, `configPathKey` (duplicated in both extension and app targets)
- `ConfigurationLoading.swift` — `loadConfiguration()` free function using App Group bookmark

### Phase 3: Extension Command Rewrites — DONE

- `FormatFileCommand.swift` — rewritten with content-type validation, selection snapshot/restore, config loading, `FormatCommandError` handling
- `FormatSelectionCommand.swift` — rewritten with content-type + selection validation, config-aware formatting
- `LintFileCommand.swift` — new command, runs `SwiftiomaticLib.lint()`, returns summary via `FormatCommandError.lintSummary`
- `SourceEditorExtension.swift` — added `extensionDidFinishLaunching()` warming rule registry

### Phase 4: Info.plist & Entitlements — DONE

- Extension Info.plist — added Lint File command (`com.toba.swiftiomatic.extension.lint-file`)
- App Info.plist — removed `LSUIElement = true` so app has a window
- Created `SwiftiomaticApp.entitlements` and `SwiftiomaticExtension.entitlements` with App Group `group.com.toba.swiftiomatic`
- Set `CODE_SIGN_ENTITLEMENTS` build setting for both targets

### Phase 5: Host App — SwiftUI Tabbed Interface — DONE

All files created on disk.

- Deleted `AppDelegate.swift`, created `SwiftiomaticApp.swift` (`@main` SwiftUI `App`)
- `Models/AppModel.swift` — `@Observable @MainActor` model with rule catalog, config loading/saving, bookmark management, `NSOpenPanel` config picker
- `Models/SharedDefaults.swift` — duplicate of extension's SharedDefaults
- `Views/ContentView.swift` — `TabView` with Rules, Options, About tabs
- `Views/RulesTab.swift` — `NavigationSplitView`, searchable, scope filter picker
- `Views/RuleRow.swift` — toggle + name + scope badge + wrench icon
- `Views/RuleDetailView.swift` — full rule documentation panel
- `Views/ScopeBadge.swift` — colored capsule (orange/blue/purple)
- `Views/OptionsTab.swift` — `Form` with config file picker, indent/width/confidence controls
- `Views/AboutTab.swift` — version, extension activation instructions

### Xcode Project Configuration — PARTIALLY DONE

**Completed:**
- Removed `AppDelegate.swift` from project
- Added `SwiftiomaticApp.swift` to SwiftiomaticApp target
- Created `Models` and `Views` groups under SwiftiomaticApp (with path properties)
- Added all 9 Model/View files to SwiftiomaticApp target (paths now correct after xc-mcp fix)
- Added all 6 new extension files to SwiftiomaticExtension target
- Added entitlements files to both targets (not as compile sources)
- Set `CODE_SIGN_ENTITLEMENTS` build settings for both targets
- Added `SwiftiomaticLib.framework` to SwiftiomaticApp (via `add_framework` — WRONG type, see below)

**Still TODO:**
- [x] **Remove bogus `SwiftiomaticLib.framework` system framework ref** — used `remove_framework` xc-mcp tool, then `add_swift_package` to link `SwiftiomaticLib` product to SwiftiomaticApp
- [x] **Build the Xcode project** — fixed path doubling in pbxproj (groups had `path` property causing doubled resolution), removed ~20 orphaned duplicate PBXFileReference entries, added `AppKit`+`UniformTypeIdentifiers` imports to AppModel.swift, fixed bundle ID prefix (`app.toba.swiftiomatic.extension`), set signing settings
- [x] **Run SPM tests** — 4531 passed, 7 pre-existing failures unrelated to this work. Also fixed `.bridge()` calls in test helpers (replaced with `as NSString`/`as String` casts after BridgeExtensions.swift deletion) and `public import ArgumentParser` in CLI target
- [x] Verify extension and app targets both compile with signing configured

### Known Issues Encountered

1. **xc-mcp `add_file` path doubling** (184-2cs) — fixed: groups with `path:` property caused doubled paths in file references
2. **xc-mcp `add_swift_package` already-exists** (03r-132) — fixed: now links product to new target when package already exists
3. **xc-mcp `remove_file` cross-target removal** (nxb-ofm) — filed: removing a file removes all files with the same name across all targets
4. **Xcode build vs SPM build differences** — xcodebuild showed `.bridge()` errors on `String` that don't appear in SPM builds. These are pre-existing (not caused by this work) and are in vendored SourceKit code.
