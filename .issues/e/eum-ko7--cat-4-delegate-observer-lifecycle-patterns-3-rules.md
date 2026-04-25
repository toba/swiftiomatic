---
# eum-ko7
title: 'Cat 4: Delegate, Observer & Lifecycle Patterns (3 rules)'
status: completed
type: feature
priority: normal
created_at: 2026-04-15T00:27:58Z
updated_at: 2026-04-25T22:54:31Z
parent: qlt-10c
sync:
    github:
        issue_number: "313"
        synced_at: "2026-04-25T22:56:03Z"
---

Catch common reference-cycle and lifecycle bugs.

| SwiftLint Rule | Swiftiomatic Name | Scope | Description |
|---|---|---|---|
| `class_delegate_protocol` | DelegateProtocolRequiresAnyObject | `.lint` | Delegate protocols should be `AnyObject`-constrained for `weak` references |
| `weak_delegate` | WeakDelegates | `.lint` | Delegate properties should be `weak` to prevent retain cycles |
| `notification_center_detachment` | DeinitObserverRemoval | `.lint` | Only remove NotificationCenter observer in `deinit` |



## Summary of Changes

Added three Cat 4 lint rules in `Sources/SwiftiomaticKit/Rules/`:

- `DelegateProtocolRequiresAnyObject` — flags `*Delegate` protocols that aren't class-constrained (handles `: AnyObject`/`NSObjectProtocol`/`Actor`/`*Delegate` inheritance, composition types, `where Self: …` clauses, `@objc`, and `: class`).
- `WeakDelegates` — flags class instance `*delegate` properties not declared `weak`/`unowned`. Excludes protocol requirements, struct/enum/actor members, computed properties, declarations inside accessor bodies, locals inside functions/closures, and the `@UIApplicationDelegateAdaptor` / `@NSApplicationDelegateAdaptor` / `@WKExtensionDelegateAdaptor` SwiftUI adaptors.
- `DeinitObserverRemoval` — flags `NotificationCenter.default.removeObserver(self)` outside `deinit` (skips the entire `deinit` subtree).

Logic ported from SwiftLint references at `~/Developer/swiftiomatic-ref/SwiftLint/Source/SwiftLintBuiltInRules/Rules/Lint/{ClassDelegateProtocolRule,WeakDelegateRule,NotificationCenterDetachmentRule}.swift`.

Tests: 29 new test cases in `Tests/SwiftiomaticTests/Rules/{DelegateProtocolRequiresAnyObjectTests,WeakDelegatesTests,DeinitObserverRemovalTests}.swift`. Generated files (`Pipelines+Generated.swift`, `ConfigurationRegistry+Generated.swift`, `ConfigurationSchema+Generated.swift`, `schema.json`) regenerated via `swift run Generator`. Full suite: 2824 passed, 0 failed.
