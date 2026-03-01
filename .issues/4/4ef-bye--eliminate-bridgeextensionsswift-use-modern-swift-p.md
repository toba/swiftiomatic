---
# 4ef-bye
title: Eliminate BridgeExtensions.swift — use modern Swift path APIs and inline casts
status: completed
type: task
priority: normal
created_at: 2026-03-01T02:43:24Z
updated_at: 2026-03-01T02:49:19Z
sync:
    github:
        issue_number: "114"
        synced_at: "2026-03-01T03:57:27Z"
---

## Context

`Sources/Swiftiomatic/SourceKit/BridgeExtensions.swift` provides trivial `.bridge()` extensions that cast Swift types to their NS counterparts (`String` → `NSString`, `Array` → `NSArray`, etc.). This is a SwiftLint-era pattern that obscures intent and avoids modern Swift APIs.

## Migration Plan

- [ ] Replace `string.bridge().lastPathComponent` → `URL(fileURLWithPath:).lastPathComponent`
- [ ] Replace `string.bridge().deletingPathExtension` → `URL(fileURLWithPath:).deletingPathExtension().lastPathComponent`
- [ ] Replace `string.bridge().appendingPathComponent(_:)` → `URL(fileURLWithPath:).appending(path:)`
- [ ] Replace `string.bridge().replacingCharacters(in:with:)` → native String range replacement
- [ ] Replace `string.bridge().fullNSRange` → `NSRange(string.startIndex..., in: string)`
- [ ] Replace `dictionary.bridge()` / `array.bridge()` → inline `as NSDictionary` / `as NSArray`
- [ ] Delete `BridgeExtensions.swift`
- [ ] Verify all tests pass

## Files

~20 call sites across Sources/:
- `Configuration/Configuration.swift`
- `Support/Glob.swift`
- `SourceKit/JSONOutput.swift`, `SyntaxToken.swift`
- `Rules/Naming/Files/FileNameRule.swift`, `FileNameNoSpaceRule.swift`, `FileNameRule+Configuration.swift`
- `Rules/Ordering/Sorting/FileHeaderRule+Configuration.swift`
- `Rules/Documentation/Annotations/TodoRule.swift`
- `Rules/TypeSafety/Types/SyntacticSugarRule.swift`
- `Rules/ControlFlow/Closures/ExplicitSelfRule.swift`
- `Rules/ControlFlow/Conditionals/UnavailableFunctionRule.swift`
- `Rules/DeadCode/Unused/UnusedImportRule.swift`


## Summary of Changes

- Deleted `Sources/Swiftiomatic/SourceKit/BridgeExtensions.swift`
- Replaced `.bridge().lastPathComponent` / `.deletingPathExtension` / `.appendingPathComponent` with `URL(fileURLWithPath:)` APIs in 6 files
- Replaced `.bridge()` NSString manipulation (`.replacingCharacters(in:with:)`, `.fullNSRange`, `.lengthOfBytes`) with inline `as NSString` casts or native Swift equivalents in 5 files
- Replaced `.bridge()` collection casts with inline `as NSDictionary` in 2 files
- Migrated test helper `.bridge()` calls in 2 test files
- Added missing `import Foundation` to `SyntaxToken.swift`
- Two `.bridge()` references remain in `UnavailableFunctionRule.swift` — these are inside example string literals (test fixture code), not actual calls
