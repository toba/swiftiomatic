---
# ci5-yge
title: Modernize Sources/Swiftiomatic/SourceKit/
status: completed
type: task
priority: normal
created_at: 2026-02-28T17:25:38Z
updated_at: 2026-02-28T18:18:52Z
---

Swift review findings for the SourceKit/ vendored module. Ordered by priority.

## High Priority

- [x] Replace `SourceKitRepresentable` protocol with recursive `SourceKitValue` enum — eliminates all `as?`/`as!` casts from response handling (Request.swift, SyntaxMap.swift, SwiftDocKey.swift, SourceKitResolver.swift, JSONOutput.swift, Structure.swift)
- [x] Replace `File`'s two `DispatchQueue`s with `Mutex<FileState>` — removes `@unchecked Sendable` (File.swift:62-63)

## Medium Priority

- [x] Add typed throws `throws(Request.Error)` to `Request.send()` and `Request.asyncSend()` — consolidate inline `SourceKitSendError` into `Request.Error` (Request.swift:206-227, SourceKitObject.swift:114)
- [x] Propagate typed throws to `Structure.init(file:)` and `SyntaxMap.init(file:)` (Structure.swift:13, SyntaxMap.swift:24)
- [x] Audit `SourceKitResolver` `@unchecked Sendable` — `compilerArgs` is `let`, `indexCache` is `Mutex`; `@unchecked` cannot be dropped because `Request.send()` uses `DispatchSemaphore` internally and touches global C state via sourcekitd XPC. Correctly documented in code comment.
- [x] Delete redundant hand-written `==` for `SyntaxMap` and `SyntaxToken` — both already conform to `Equatable` with equatable stored properties (SyntaxMap.swift:83-89, SyntaxToken.swift:26-28)
- [x] Add `LocalizedError` conformance to `Request.Error` (Request.swift:230)
- [x] Change `isSwiftFile()` / `isObjectiveCHeaderFile()` from methods to computed properties (String+SourceKit.swift:15,31)

## Low Priority

- [x] Replace `AnySequence` in `StringView` line enumeration with conditional loop (StringView.swift:73-76)
- [x] Simplify `DocCommentFinder.getRangeForDeclaration` — uses `prefix`/`removeFirst` instead of `replaceSubrange` (SyntaxMap.swift:64)
- [x] Consider extending `sourcekitd_response_t` with `@retroactive Sendable` — not practical; `sourcekitd_response_t` is `typedef void *`, so `@retroactive Sendable` on `UnsafeMutableRawPointer` would be overbroad. `UncheckedSendableValue` wrapper is the correct approach.
- [x] Note: `sourceKitWaitingRestoredSemaphore` DispatchSemaphore is tech debt but deeply embedded in sync `send()` path — acknowledged, not actionable without rewriting sync path

## Swiftlint

- [x] Fix 6 `force_cast` violations — resolved by SourceKitValue enum change
- [x] Fix 1 `force_try` violation (String+SourceKit.swift:43) — suppressed with `sm:disable:this force_try` (static regex pattern, cannot fail)
- [x] Fix 8 `pattern_matching_keywords` violations — resolved by SourceKitValue refactor (old `as?` cast patterns no longer exist)
- [x] Fix 1 `fatal_error_message` violation (StringView.swift:177) — already has descriptive messages
- [x] 22 `legacy_objc_type` warnings are inherent to the NSString/Foundation bridging in this vendored code — accepted; 19 remain, all in BridgeExtensions/JSONOutput/String+SourceKit/StringView

## Summary of Changes

- Replaced `SourceKitRepresentable` (protocol over `Any`) with `SourceKitValue` recursive enum — type-safe response handling throughout
- Replaced `File`'s `DispatchQueue`-based synchronization with `Mutex<FileState>` — proper Sendable conformance
- Added typed throws `throws(Request.Error)` to `Request.send()`, `asyncSend()`, `Structure.init(file:)`, `SyntaxMap.init(file:)`
- Added `LocalizedError` conformance to `Request.Error`
- Deleted redundant hand-written `Equatable` for `SyntaxMap`/`SyntaxToken`
- Converted `isSwiftFile`/`isObjectiveCHeaderFile` to computed properties
- Simplified `DocCommentFinder` and `StringView` line enumeration
- Audited `@unchecked Sendable` — documented why it's required on `SourceKitResolver`
- Resolved all actionable swiftlint violations; accepted inherent `legacy_objc_type` warnings
