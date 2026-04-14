---
# ft5-6do
title: Clean up debug prints and fatalError patterns
status: ready
type: task
priority: low
created_at: 2026-04-14T02:42:23Z
updated_at: 2026-04-14T02:42:23Z
parent: kqx-iku
sync:
    github:
        issue_number: "269"
        synced_at: "2026-04-14T02:58:30Z"
---

## 1. Debug print() in PrettyPrint.swift
`Sources/Swiftiomatic/PrettyPrint/PrettyPrint.swift` uses bare `print()` for error conditions:
- Line 614: `print("Bad index 1")`
- Line 622: `print("Bad index 2")`

These should use `assertionFailure()` or proper diagnostics, not stdout.

## 2. assert(false) should be fatalError/preconditionFailure
`Sources/Swiftiomatic/PrettyPrint/PrettyPrint.swift:728`:
```swift
assert(false, "Open tokens must be closed.")
```
`assert(false)` is stripped in release builds. Use `fatalError()` or `preconditionFailure()` for invariant violations that should never be silent.

## 3. fatalError for subclass override pattern
`Sources/sm/Frontend/Frontend.swift:256`:
```swift
fatalError("Must be overridden by subclasses.")
```
Consider making `Frontend` a protocol or using an abstract method pattern instead.

## 4. Stale TODOs
- `Sources/sm/PrintVersion.swift:14` — "TODO: Automate updates to this somehow." (version hardcoded as "main")
- `Sources/Swiftiomatic/PrettyPrint/PrettyPrint.swift:612, 619` — "TODO(dabelknap): Handle the unwrapping more gracefully"

## Tasks
- [ ] Replace debug prints with assertionFailure
- [ ] Replace assert(false) with preconditionFailure
- [ ] Evaluate Frontend subclass override pattern
- [ ] Address or remove stale TODOs
