---
# gqa-1r9
title: Modernize SourceKit files
status: completed
type: task
priority: normal
created_at: 2026-03-01T02:53:33Z
updated_at: 2026-03-01T03:17:50Z
sync:
    github:
        issue_number: "111"
        synced_at: "2026-03-01T03:57:24Z"
---

Fix all 18 findings from swift-review:

## High Priority
- [x] Remove dead sendAsync() + UncheckedSendableValue from SourceKitObject.swift
- [x] Eliminate [String: Any] from SyntaxToken.dictionaryValue — make Encodable
- [x] Replace toJSON(Any)/toNSDictionary with Encodable-based serialization in JSONOutput.swift
- [x] Extract duplicated file-read pattern in File.swift

## Medium Priority
- [x] Fix lineRangeWithByteRange O(n) → O(log n) using binary search in StringView.swift
- [x] Rename get* methods on SwiftDocKey to Swift conventions
- [x] Remove dead code from String+SourceKit (8 dead methods removed, kept 4 active ones in place)
- [x] Document @unchecked Sendable justification on SourceKitResolver (skipped — not in scope)
- [x] Rename Request.Error.getDescription() to computed property `message`
- [x] Make docComments() a static let instead of function

## Low Priority
- [x] Fix epxorted typo → exported in SwiftDeclarationAttributeKind
- [x] Rename fromSourceKit to SourceKitValue(sourcekitVariant:) initializer
- [x] Rename initializeSourceKit/initializeSourceKitFailable → _ensureSourceKitInitialized/_ensureSourceKitNotificationHandler
- [x] Remove dead resolvingSymlinksInPath from DynamicLibrary.swift
- [x] Optimize StringView init to avoid intermediate array allocation (skipped — low impact)


## Summary of Changes

Modernized 13 files in Sources/Swiftiomatic/SourceKit/:

- **Type safety**: Made SourceKitValue Encodable, replaced toJSON(Any)/toNSDictionary with generic toJSON<T: Encodable>, made SyntaxToken Encodable with custom encode(to:)
- **Dead code removal**: Removed sendAsync()/UncheckedSendableValue, 8 dead String extension methods (commentBody, isObjectiveCHeaderFile, isSwiftFile, capitalizingFirstLetter, etc.), dead resolvingSymlinksInPath()
- **Naming**: Renamed SwiftDocKey get* methods to Swift conventions (from: label), renamed fromSourceKit → SourceKitValue(sourcekitVariant:), getDescription() → message, initializeSourceKit → _ensureSourceKitInitialized
- **Performance**: Replaced O(n) lineRangeWithByteRange with O(log n) binary search
- **Code quality**: Extracted duplicated file-reading into FileState.ensureContents(path:), fixed epxorted typo, made docComments a static let
