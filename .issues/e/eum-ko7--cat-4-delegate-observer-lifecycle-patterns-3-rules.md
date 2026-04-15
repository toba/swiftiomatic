---
# eum-ko7
title: 'Cat 4: Delegate, Observer & Lifecycle Patterns (3 rules)'
status: ready
type: feature
priority: normal
created_at: 2026-04-15T00:27:58Z
updated_at: 2026-04-15T00:27:58Z
parent: qlt-10c
sync:
    github:
        issue_number: "313"
        synced_at: "2026-04-15T00:34:45Z"
---

Catch common reference-cycle and lifecycle bugs.

| SwiftLint Rule | Swiftiomatic Name | Scope | Description |
|---|---|---|---|
| `class_delegate_protocol` | DelegateProtocolRequiresAnyObject | `.lint` | Delegate protocols should be `AnyObject`-constrained for `weak` references |
| `weak_delegate` | WeakDelegates | `.lint` | Delegate properties should be `weak` to prevent retain cycles |
| `notification_center_detachment` | DeinitObserverRemoval | `.lint` | Only remove NotificationCenter observer in `deinit` |
