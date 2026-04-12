---
# dz3-tm5
title: Add SwiftiomaticApp unit tests
status: scrapped
type: task
priority: normal
created_at: 2026-04-12T15:57:34Z
updated_at: 2026-04-12T18:15:03Z
sync:
    github:
        issue_number: "218"
        synced_at: "2026-04-12T18:23:35Z"
---

The SwiftiomaticApp Xcode target has zero test coverage. There is no test target in the Xcode project and the scheme has an empty `<Testables>` section.

## Source files needing coverage

### Models (highest priority — testable logic)
- `AppModel.swift` (102 lines) — rule catalog loading, `isRuleEnabled()` (opt-in/disabled logic), `toggleRule()`, config persistence via app group `UserDefaults`, YAML serialization round-trip
- `SharedDefaults.swift` (10 lines) — app group suite creation

### Views (lower priority — mostly layout)
- `ContentView.swift` — tab structure
- `RulesTab.swift` — scope filtering (`ScopeFilter` enum, `filteredRules` computed property), search filtering
- `RuleRow.swift` — toggle binding
- `RuleDetailView.swift` — detail display
- `OptionsTab.swift` — format bindings (indentation, max width, min confidence)
- `AboutView.swift` — version/build display
- `ScopeBadge.swift` — scope-to-color mapping

## Requirements

- [ ] Create an Xcode UI test target (`SwiftiomaticAppTests`) in `Xcode/Swiftiomatic.xcodeproj`
- [ ] Add the test target to the Swiftiomatic scheme's Testables
- [ ] Write unit tests for `AppModel`:
  - [ ] `isRuleEnabled()` — default-on rules return true, opt-in rules return false, disabled rules return false
  - [ ] `toggleRule()` — toggling on/off updates `enabledLintRules`/`disabledLintRules` correctly
  - [ ] Format/suggest rules are always enabled and not toggleable
  - [ ] Config round-trip: persist to app group → load from app group produces equivalent config
- [ ] Write unit tests for `RulesTab.ScopeFilter` filtering logic
- [ ] Write unit tests for `OptionsTab` binding logic (indentation type switch, indent width clamping)

## Notes

- Use Swift Testing (`import Testing`, `@Test`, `#expect`) — not XCTest
- The existing SPM test target (`SwiftiomaticTests`) covers SwiftiomaticKit/SwiftiomaticSyntax only — it does not test the app
- `AppModel` is `@MainActor` — tests will need `@MainActor` as well
- Consider whether `AppModel` logic can be tested without a real app group suite (mock `UserDefaults`)


## Reasons for Scrapping

The app target is a thin SwiftUI shell around SwiftiomaticKit. The "testable logic" (rule enable/disable, config persistence) is trivial UserDefaults wrapping — tests would just mirror the implementation without catching real bugs. For a small macOS app, this is another thing to update with every UI change for no practical benefit. The core logic lives in SwiftiomaticKit/SwiftiomaticSyntax and is already well-tested.
