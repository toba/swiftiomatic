---
# ft5-6do
title: Clean up debug prints and fatalError patterns
status: completed
type: task
priority: low
created_at: 2026-04-14T02:42:23Z
updated_at: 2026-04-14T03:01:39Z
parent: kqx-iku
sync:
    github:
        issue_number: "269"
        synced_at: "2026-04-14T03:02:33Z"
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
- [x] Replace debug prints with assertionFailure
- [x] Replace assert(false) with preconditionFailure
- [x] Evaluate Frontend subclass override pattern (kept — standard Swift class hierarchy pattern with shared implementation)
- [x] Address or remove stale TODOs


## Summary of Changes

- Replaced `print("Bad index 1/2")` with `assertionFailure()` in PrettyPrint.swift
- Replaced `assert(false, ...)` with `preconditionFailure()` in PrettyPrint.swift
- Updated stale TODO in PrintVersion.swift to reference issue 0w5-3pm
- Frontend `fatalError` override pattern left as-is — it's a standard Swift abstract-method pattern for class hierarchies with shared implementation
