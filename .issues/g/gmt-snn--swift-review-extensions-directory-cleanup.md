---
# gmt-snn
title: 'Swift review: Extensions directory cleanup'
status: completed
type: task
priority: normal
created_at: 2026-02-28T19:30:50Z
updated_at: 2026-02-28T19:45:34Z
---

Thorough swift-review of Sources/Swiftiomatic/Extensions/ — formatting, all 8 review categories, file/type naming.

## Tasks

- [x] Step 1: Format and lint
- [x] Step 2: File renames and splits (Array+Parallel, SourceRange, String+Utilities, SwiftSyntax+Analysis, SwiftSource+Regex)
- [x] Step 3: Type renames (SwiftLintSyntaxVisitor→TreeWalkable, MutableWrapper→SendableMutableBuffer, ImmutableWrapper→SendableBuffer, Box→CacheStorage)
- [x] Step 4.1: Cache factory outside Mutex lock (HIGH perf)
- [x] Step 4.2: Typed throws for sendIfNotDisabled (MEDIUM)
- [x] Step 4.3: Method→property naming (LOW)
- [x] Step 4.4: Legacy SwiftLint references (LOW)
- [x] Step 4.5: sha256 hex encoding perf (LOW)
- [x] Step 4.6: Force-unwrap safety (LOW)


## Summary of Changes

### File Splits (3 files → 10)
- **Array+Parallel.swift** → `Array+Parallel.swift` (grouping/parallel ops), `Array+Uniquing.swift` (unique, array(of:)), `Collection+Conveniences.swift` (isNotEmpty, onlyElement)
- **SwiftSyntax+Analysis.swift** → `SwiftSyntax+Declarations.swift`, `SwiftSyntax+Expressions.swift`, `SwiftSyntax+Trivia.swift`, `SwiftSyntax+TreeWalking.swift`
- **SwiftSource+Regex.swift** → `SwiftSource+Matching.swift`, `SwiftSource+FileIO.swift`, `SwiftSource+Regions.swift`

### File Renames (2)
- `SourceRange+SwiftLint.swift` → `SourceRange+Contains.swift`
- `String+Utilities.swift` → `String+PathAndRange.swift`

### Type Renames (4)
- `SwiftLintSyntaxVisitor` → `TreeWalkable`
- `MutableWrapper` → `SendableMutableBuffer`
- `ImmutableWrapper` → `SendableBuffer`
- `Box` → `CacheStorage` (in Cache class)

### Code Changes
- **Cache.get() double-check locking**: Factory now executes outside Mutex lock — major contention reduction for expensive SourceKit calls
- **Typed throws**: `sendIfNotDisabled()` now `throws(Request.Error)`, narrowing catch in responseCache
- **Method→property**: `hasTrailingWhitespace()` → `var hasTrailingWhitespace`, `isUppercase()` → `var isUppercase`, `isLowercase()` → `var isLowercase`; callers updated in 3 rule files
- **toHexString()** → `var hexString` with pre-sized allocation (eliminates 32 String(format:) allocations per SHA256)
- **Force-unwrap safety**: `URL.filepath` uses guard+preconditionFailure; `String.substring(from:)` uses guard+preconditionFailure; `String.sha256()` documented why force-unwrap is safe
- **Legacy naming**: SR-10121 comment updated, SwiftLint references removed from protocol/filenames
