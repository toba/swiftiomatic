---
# 95w-eow
title: 'Lint rules: pre-OS 26 NotificationCenter patterns'
status: completed
type: feature
priority: normal
created_at: 2026-06-12T14:57:56Z
updated_at: 2026-06-12T15:16:21Z
sync:
    github:
        issue_number: "729"
        synced_at: "2026-06-12T15:17:18Z"
---

Add lint rules that flag pre-OS 26 NotificationCenter usage in favor of the typed Message API (SE-0011, `NotificationCenter.MainActorMessage` / `AsyncMessage`, `addObserver(of:for:)`, `messages(of:)`, `post(_:subject:)`).

## Background

On macOS 26 / iOS 26+ targets, legacy NotificationCenter patterns are effectively deprecated relative to the new typed-message API. Detection is mechanical and a good fit for swiftiomatic; the *fix* mostly isn't (it requires inferring struct shape from runtime `userInfo` keys) so these rules are **warn-only / no autofix** by default.

Reference: https://www.nutrient.io/blog/notification-center/ and Foundation proposal SE-0011.

## Proposed rules

### `notification-selector-observer` (severity: error, no fix)
Match calls to `NotificationCenter.*.addObserver(_:selector:name:object:)` (the selector overload, takes `self` / an object as first positional arg). This pattern requires `@objc` + NSObject, is stringly-typed, and crashes if the method signature changes. Always wrong on OS 26+.

Message: `Selector-based NotificationCenter observers are unsafe and legacy. Use addObserver(of:for:) with a typed Message, or addObserver(forName:object:queue:) with a closure.`

### `notification-name-extension` (severity: warning, no fix)
Match declarations of `extension Notification.Name { static let X = Notification.Name("...") }` and `Notification.Name(rawValue:)` literal forms.

Message: `Custom Notification.Name is pre-OS 26. Prefer a NotificationCenter.MainActorMessage (or AsyncMessage) struct for type- and isolation-safety.`

### `notification-adapted-system-name` (severity: info, no fix)
Match `addObserver(forName:...)`, `.notifications(named:)`, and `post(name:...)` where the name argument matches a small **static allow-list** of system notifications that have shipped a MainActorMessage adapter in the current SDK.

Suggested message: `<X.YNotification> has a typed adapter <X.YMessage> on OS 26+. Prefer addObserver(of:for:) / messages(of:).`

**Initial allow-list — full inventory pulled from `MacOSX26.5.sdk` + `iPhoneOS26.5.sdk` `.swiftinterface` files (Dec 2026).** Generate / regenerate by grepping `$(xcrun --sdk macosx --show-sdk-path)/System/Library/Frameworks/<F>.framework/Modules/<F>.swiftmodule/*.swiftinterface` for `MainActorMessage`.

Foundation (cross-platform):
- `NSCalendarDayChanged` → `Date.SystemClockDidChangeMessage` (system-clock-shaped)
- `NSSystemClockDidChange` → `Date.SystemClockDidChangeMessage`
- `NSSystemTimeZoneDidChange` → `TimeZone.SystemTimeZoneDidChangeMessage`
- `NSCurrentLocaleDidChange` → `Locale.CurrentLocaleDidChangeMessage`
- `NSUbiquityIdentityDidChange` → `FileManager.UbiquityIdentityDidChangeMessage`
- `UserDefaults.sizeLimitExceededNotification` → `UserDefaults.SizeLimitExceededMessage`
- `NSExtensionHostDidBecomeActive` / `DidEnterBackground` / `WillEnterForeground` / `WillResignActive` → `NSExtensionContext.{DidBecomeActive,DidEnterBackground,WillEnterForeground,WillResignActive}Message`
- `NSUndoManagerCheckpoint` → `UndoManager.CheckpointMessage`
- `NSUndoManagerDidOpenUndoGroup` → `UndoManager.DidOpenUndoGroupMessage`
- `NSUndoManagerDidCloseUndoGroup` → `UndoManager.DidCloseUndoGroupMessage`
- `NSUndoManagerWillCloseUndoGroup` → `UndoManager.WillCloseUndoGroupMessage`
- `NSUndoManagerDidUndoChange` → `UndoManager.DidUndoChangeMessage`
- `NSUndoManagerDidRedoChange` → `UndoManager.DidRedoChangeMessage`
- `NSUndoManagerWillUndoChange` → `UndoManager.WillUndoChangeMessage`
- `NSUndoManagerWillRedoChange` → `UndoManager.WillRedoChangeMessage`

AppKit (macOS only — sparse):
- `NSApplication.{shouldBeginSuppressing,shouldEndSuppressing}HighDynamicRangeContentNotification` → `NSApplication.{ShouldBeginSuppressing,ShouldEndSuppressing}HighDynamicRangeContentMessage`
- `NSWorkspace.didHideApplicationNotification` → `NSWorkspace.DidHideApplicationMessage` (and the symmetric `DidUnhide/WillLaunch/DidLaunch/DidTerminate/DidActivate/DidDeactivateApplication`)
- `NSWorkspace.willSleepNotification` / `didWakeNotification` → `WillSleepMessage` / `DidWakeMessage`
- `NSWorkspace.didMountNotification` / `willUnmountNotification` / `didUnmountNotification` / `didRenameVolumeNotification` → `Did/WillUnmount/DidRenameVolumeMessage`
- `NSWorkspace.sessionDidBecomeActiveNotification` / `sessionDidResignActiveNotification` → matching messages
- `NSWorkspace.didChangeFileLabelsNotification` → `NSWorkspace.DidChangeFileLabelsMessage`
- `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification` → `NSWorkspace.AccessibilityDisplayOptionsDidChangeMessage`

UIKit (iOS / Catalyst — extensive; partial list, ~70 total):
- `UIApplication.{didFinishLaunching,didBecomeActive,didEnterBackground,willEnterForeground,willResignActive,willTerminate,didReceiveMemoryWarning,significantTimeChange,backgroundRefreshStatusDidChange,userDidTakeScreenshot,protectedDataDidBecomeAvailable,protectedDataWillBecomeUnavailable}Notification` → `UIApplication.<Same>Message`
- `UIScene.{willConnect,didActivate,willDeactivate,willEnterForeground,didEnterBackground}Notification`, `UIScene.systemProtectionDidChangeNotification` → `UIScene.<Same>Message`
- `UIResponder.keyboard{WillShow,DidShow,WillHide,DidHide,WillChangeFrame,DidChangeFrame}Notification` → `UIResponder.<Same>Message`
- `UIWindow.{didBecomeVisible,didBecomeHidden,didBecomeKey,didResignKey}Notification` → `UIWindow.<Same>Message`
- `UIScreen.{brightnessDidChange,modeDidChange,capturedDidChange,referenceDisplayModeStatusDidChange}Notification` → matching messages
- `UIDevice.{batteryLevelDidChange,batteryStateDidChange,orientationDidChange,proximityStateDidChange}Notification` → matching messages
- `UITextField.{textDidBeginEditing,textDidChange,textDidEndEditing}Notification` → `UITextField.<Same>Message`
- `UITextView.{textDidBeginEditing,textDidChange,textDidEndEditing}Notification` → `UITextView.<Same>Message`
- `UIPasteboard.{changed,removed}Notification` → `UIPasteboard.{Changed,Removed}Message`
- `UIAccessibility.*StatusDidChangeNotification` (~20 of these — VoiceOver, ReduceMotion, BoldText, Grayscale, InvertColors, etc.) → `UIAccessibility.<Same>Message`
- `UIContentSizeCategory.didChangeNotification` → `UIContentSizeCategory.DidChangeMessage`
- `UITextInputMode.currentInputModeDidChangeNotification` → `UITextInputMode.CurrentInputModeDidChangeMessage`
- `UIPointerLockState.didChangeNotification` → `UIPointerLockState.DidChangeMessage`
- `UIViewController.showDetailTargetDidChangeNotification` → `UIViewController.ShowDetailTargetDidChangeMessage`
- `UITableView.selectionDidChangeNotification` → `UITableView.SelectionDidChangeMessage`
- `UIDocument.stateChangedNotification` → `UIDocument.StateChangedMessage`
- `UIFocusSystem.{didUpdate,movementDidFail}Notification` → matching messages

Other frameworks: HealthKit (`HKUserPreferencesDidChangeMessage` etc.), EventKit (`EventStoreChanged`), GameController, iTunesLibrary (`DidChangeLibraryMessage`).

**Notifications WITHOUT adapters as of 26.5 — do NOT flag** (AsyncSequence is the modern form):
- `NSView.boundsDidChangeNotification`, `NSView.frameDidChangeNotification`
- `NSWindow.*Notification` (e.g. `didBecomeKey`, `didResignKey`, `willClose`) — **asymmetric with UIKit's `UIWindow`**, which IS adapted
- `NSText`, `NSTextView`, `NSTextStorage` notifications
- `NSResponder`, `NSControl` notifications

**Strong recommendation:** generate the allow-list from the SDK at swiftiomatic build time rather than maintain it by hand — a `Scripts/generate-notification-adapters.sh` that greps `MainActorMessage` from `$(xcrun --sdk {macosx,iphoneos} --show-sdk-path)` swiftinterfaces and emits a `[String: String]` literal keeps coverage current per SDK release.

## Notes / open questions

- Allow-list maintenance: needs review per Xcode SDK release. Consider sourcing from a generated table (grep SDK headers for `MainActorMessage` conformances) rather than hand-maintained.
- Deployment-target gating: rules should only fire when the project's minimum target is macOS 26 / iOS 26 — otherwise the suggested API isn't available. Check existing swiftiomatic mechanism for reading min-deployment.
- No autofix: the producer-side post call carries the `userInfo` keys that determine the message struct's properties; cross-call-site inference is out of scope for a lint pass. Leave the refactor manual.
- The Thesis project audit that motivated this turned up 6 sites (all system notifications). With the corrected/expanded allow-list, 4 are migratable: `UIApplication.willResignActiveNotification` (SyncEngine) + the three `NSUndoManager.*` AsyncSequence sites in `UndoState.swift` (`DidCloseUndoGroup`, `DidUndoChange`, `DidRedoChange` are all adapted under `UndoManager.*Message` in Foundation). Only `NSView.boundsDidChangeNotification` truly has no adapter and must stay on AsyncSequence.

## Related

- Thesis `/swift` skill now documents this as a review item (`~/.claude/skills/swift/SKILL.md` §5 NotificationCenter.Message block, `references/notification-messages.md` adapter table).



## Design Decision: Three rules, one helper

Keep three separate rules (different severities, different disable knobs, different node-match logic). Share an internal helper module `NotificationAPI` for the adapter allow-list and name/receiver matchers.

No deployment-target gate — project supports OS 26+ only.

## Tasks

- [x] Add `NotificationAPI` helper (adapter allow-list, name/receiver detection)
- [x] ~~Add `NotificationSelectorObserver`~~ — already covered by existing `UseClosureNotificationObserver` (Swiftui group)
- [x] Add `UseTypedNotificationName` lint rule (no fix) — covers `extension Notification.Name` + `Notification.Name("…")` / `Notification.Name(rawValue:)` literal forms
- [x] Add `UseTypedSystemNotification` lint rule (no fix) — matches `addObserver(forName:)` / `notifications(named:)` / `messages(named:)` / `post(name:)` against the SDK-derived + Foundation-legacy adapter tables
- [x] Generate adapter allow-list from SDK swiftinterfaces (`Scripts/generate-notification-adapters.sh`) — emits `NotificationAdapters+Generated.swift` with 121 entries from macOS 26.5 + iOS 26.5 SDKs
- [x] Tests for each rule
- [x] Full suite passes (3456 / 3456)



## Summary of Changes

- Added `Scripts/generate-notification-adapters.sh` that scans macOS + iOS SDK swiftinterfaces for `NotificationCenter.MainActorMessage` adapters and emits `Sources/SwiftiomaticKit/Rules/Swiftui/NotificationAdapters+Generated.swift` (121 entries from 26.5 SDKs).
- Added `NotificationAPI` helper with the SDK-generated table, a hand-curated Foundation legacy-name supplement (17 free-floating `NS*` names that don't appear in swiftinterfaces), and shared matchers (`adapter(for:)`, `qualifiedNotificationName`, `isNotificationNameType`).
- Added `UseTypedNotificationName` lint rule (Swiftui group) — flags `extension Notification.Name { … }` and `Notification.Name("…")` / `Notification.Name(rawValue:)` literal constructions.
- Added `UseTypedSystemNotification` lint rule (Swiftui group) — flags uses of system notification names with typed adapters across `addObserver(forName:)`, `notifications(named:)`, `messages(named:)`, and `post(name:)`. Recognises both qualified `Type.memberNotification` and bare-identifier Foundation forms.
- Existing `UseClosureNotificationObserver` already covered the selector-observer case, so no third rule was needed.
- Three rules instead of one — different severities, disable knobs, and node-match logic; shared helper avoids duplication.
