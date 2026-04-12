---
# 3zl-gq6
title: 'Document-based SwiftUI app: open/create .swiftiomatic.yaml'
status: completed
type: feature
priority: normal
created_at: 2026-04-12T15:40:32Z
updated_at: 2026-04-12T18:12:45Z
sync:
    github:
        issue_number: "223"
        synced_at: "2026-04-12T18:23:35Z"
---

Redesign the macOS app as a **document-based SwiftUI app** centered on `.swiftiomatic.yaml` files.

## Requirements

- [x] App launch requires opening an existing `.swiftiomatic.yaml` or creating a new one
- [x] New documents start with default rule configuration
- [x] Standard "recently opened" list (Open Recent menu / welcome screen)
- [x] Use SwiftUI `DocumentGroup` with `ReferenceFileDocument` for native document handling
- [x] File association: register `.swiftiomatic.yaml` as a supported document type

## Notes

- This shifts the app from a utility sidebar to a proper document-based workflow
- Each open document represents one project's Swiftiomatic configuration
- Standard macOS document behaviors apply: Cmd+O to open, Cmd+N for new, recent documents in File menu


## Summary of Changes

- Replaced `WindowGroup` with `DocumentGroup` + `ReferenceFileDocument` for native document lifecycle (Cmd+O/N/S, Open Recent)
- Created `SwiftiomaticDocument` (`@Observable ReferenceFileDocument`) wrapping `Configuration` with rule toggle logic
- Deleted `AppModel` — all responsibilities moved to the document
- Added `Configuration.parse(yaml:)` throwing method to SwiftiomaticKit for schema validation
- Open panel automatically shows hidden files via `NSWindow.didUpdateNotification` observer
- Window title shows parent folder name (not filename)
- Fixed `Configuration` `Equatable`/`Hashable` to include all unified config fields
- Made `ConfigValue` `Hashable`
- Registered `public.yaml` document type in Info.plist
- Removed manual config file picker from FormatOptions

### Key learnings

- `DocumentGroup` in SwiftUI conflicts with custom `NSDocumentController` subclasses (crashes in `PlatformDocumentController.createDocumentClassIfNeeded`)
- `.fileDialogBrowserOptions(.includeHiddenFiles)` is a view modifier only, not available on scenes — doesn't affect DocumentGroup's open panel
- Workaround: observe `NSWindow.didUpdateNotification` and set `showsHiddenFiles` on any `NSOpenPanel`
- `@MainActor` on a `ReferenceFileDocument` class conflicts with the protocol's nonisolated `init(configuration:)` requirement — omit the actor annotation
