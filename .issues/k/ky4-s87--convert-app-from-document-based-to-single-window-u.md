---
# ky4-s87
title: Convert app from document-based to single-window UserDefaults-based
status: completed
type: feature
priority: high
created_at: 2026-04-13T22:02:17Z
updated_at: 2026-04-13T22:08:36Z
sync:
    github:
        issue_number: "264"
        synced_at: "2026-04-14T02:00:50Z"
---

## Background

The app currently uses `DocumentGroup` + `ReferenceFileDocument` to open/save `.swiftiomatic.yaml` files. But since the Xcode extension can only access config via UserDefaults (not the filesystem), the YAML file is really only relevant for the CLI — not the plugin or app.

When the app loads, it should just show the UserDefaults config directly, not require opening a document.

## Current Architecture

- `SwiftiomaticApp.swift` — uses `DocumentGroup(newDocument:)` scene
- `SwiftiomaticDocument.swift` — `ReferenceFileDocument` that reads/writes YAML and syncs to UserDefaults on save
- `SharedDefaults.swift` — suite `"app.toba.swiftiomatic"`, key `"configYAML"`
- All views take `@Bindable var document: SwiftiomaticDocument`
- `WindowAccessor.swift` — sets window title to parent folder name
- Extension reads config from UserDefaults via `ConfigurationLoading.swift`

## Plan

- [x] Replace `DocumentGroup` with `WindowGroup` (or single `Window`) in `SwiftiomaticApp.swift`
- [x] Create a new `@Observable` model (e.g. `ConfigStore`) that loads from and saves to UserDefaults directly
- [x] Update all views to use `ConfigStore` instead of `SwiftiomaticDocument`
- [x] Remove `SwiftiomaticDocument.swift` and `WindowAccessor.swift`
- [x] Add Import/Export menu items for `.swiftiomatic.yaml` (so users can still round-trip with CLI config)
- [x] Set a static window title (e.g. "Swiftiomatic")
- [x] Remove the `NSOpenPanel` hidden-files hack from `SwiftiomaticApp.init()`
- [x] Verify extension still reads config correctly after changes

## Files to Change

- `Xcode/SwiftiomaticApp/SwiftiomaticApp.swift`
- `Xcode/SwiftiomaticApp/Models/SwiftiomaticDocument.swift` (remove)
- `Xcode/SwiftiomaticApp/Models/SharedDefaults.swift`
- `Xcode/SwiftiomaticApp/Views/ContentView.swift`
- `Xcode/SwiftiomaticApp/Views/FormatOptions.swift`
- `Xcode/SwiftiomaticApp/Views/CategoryDetailView.swift`
- `Xcode/SwiftiomaticApp/Views/RuleRow.swift`
- `Xcode/SwiftiomaticApp/Views/WindowAccessor.swift` (remove)



## Summary of Changes

- Replaced `DocumentGroup` + `ReferenceFileDocument` with a single `Window` scene
- Created `ConfigStore` (`@Observable @MainActor`) that loads/saves config via `UserDefaults` with `didSet` auto-save
- Updated `ContentView`, `FormatOptions`, `CategoryDetailView`, `RuleRow` to use `ConfigStore` instead of `SwiftiomaticDocument`
- Added Import/Export menu items (`Cmd+O` / `Cmd+S`) using `.fileImporter`/`.fileExporter` for CLI YAML round-tripping
- Deleted `SwiftiomaticDocument.swift` and `WindowAccessor.swift`
- Removed `CFBundleDocumentTypes` from `Info.plist`
- Removed the `NSOpenPanel` hidden-files hack (no longer needed)
- Extension unchanged — still reads from the same `UserDefaults` suite
