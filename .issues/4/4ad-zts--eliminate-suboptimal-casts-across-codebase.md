---
# 4ad-zts
title: Eliminate suboptimal casts across codebase
status: completed
type: task
priority: normal
created_at: 2026-02-28T20:53:49Z
updated_at: 2026-02-28T20:53:49Z
sync:
    github:
        issue_number: "62"
        synced_at: "2026-03-01T01:01:40Z"
---

Replace NSString bridging casts, force casts, and ObjC API casts with modern Swift/URL equivalents.

- [x] `FileManager+FileDiscovery.swift` — `enumerator(atPath:)` + `as? String` → `enumerator(at:)` + URL pattern match
- [x] `Configuration.swift` — `(directory as NSString).pathComponents` / `.appendingPathComponent` → `URL(filePath:)` walk
- [x] `SwiftFormat.swift` — redundant double `as NSString` cast → single cast returning `String`
- [x] `String+SourceKit.swift` — `characterSet.bridge()` + `characterIsMember` → `UnicodeScalar` + `CharacterSet.contains`
- [x] `Configuration+LintableFiles.swift` — `NSOrderedSet` + `as! [String]` → `Set`-based `filter`
- [x] `EnumAssociable.swift` — `as! T` force casts → `as? T` with descriptive `preconditionFailure`
- [x] `FileDiscovery.swift` — `enumerator(atPath:)` + `as? String` + `as NSString` path ops → URL-based enumeration

## Summary of Changes

Replaced 7 files' worth of NSString bridging casts (`as NSString`, `.bridge()`), ObjC API casts (`as? String` from `NSDirectoryEnumerator`), a force cast (`as! [String]` from `NSOrderedSet`), and Mirror-based force casts with modern Swift equivalents: URL-based file enumeration, `CharacterSet.contains`, `Set`-based uniquing, and guarded `as?` with `preconditionFailure`.
