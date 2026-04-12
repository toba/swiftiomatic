---
# ra5-rks
title: Use standard macOS About window instead of toolbar button
status: review
type: bug
priority: normal
created_at: 2026-04-12T15:41:36Z
updated_at: 2026-04-12T15:54:00Z
sync:
    github:
        issue_number: "216"
        synced_at: "2026-04-12T16:02:57Z"
---

The app currently has a custom "About" toolbar button. This is non-standard macOS behavior.

## Requirements

- [x] Remove the "About" toolbar button
- [x] Move existing About content into the standard macOS About window (AppKit's `orderFrontStandardAboutPanel` / SwiftUI's automatic About menu item)
- [x] Ensure the standard **App Name > About** menu item shows the current content

## Notes

- macOS apps get an About menu item automatically in the app menu; custom toolbar buttons for this are unexpected UX
- The existing About content should transfer as-is into the standard panel


## Summary of Changes

- Removed the About tab from `ContentView.swift` (was 3rd tab in the `TabView`)
- Deleted `AboutTab.swift` entirely
- Created `AboutView.swift` — a dedicated SwiftUI view with app icon, version, build, copyright, and extension activation instructions
- Added a `Window("About Swiftiomatic", id: "about")` scene in `SwiftiomaticApp.swift` with proper window modifiers (`.windowResizability(.contentSize)`, `.restorationBehavior(.disabled)`, `.windowBackgroundDragBehavior(.enabled)`)
- Replaced the default About menu item using `CommandGroup(replacing: .appInfo)` + `openWindow(id:)`
- Follows the modern SwiftUI pattern per nilcoalescing.com — no Credits.html/RTF needed
