---
# m1l-gqu
title: Extract SwiftiomaticSyntax wrapper target to cache swift-syntax builds
status: completed
type: task
priority: normal
created_at: 2026-04-11T23:08:04Z
updated_at: 2026-04-12T01:32:33Z
parent: fwk-0kx
sync:
    github:
        issue_number: "202"
        synced_at: "2026-04-12T01:32:52Z"
---

Create a thin `SwiftiomaticSyntax` target that wraps all swift-syntax imports and base types. SPM caches compiled modules — if this target doesn't change, it won't recompile even when rules change. This is the simplest module split that gives real caching benefit.

## What goes in SwiftiomaticSyntax

- `@_exported import` for all swift-syntax modules: SwiftSyntax, SwiftParser, SwiftIDEUtils, SwiftOperators, SwiftSyntaxBuilder, SwiftLexicalLookup
- Base visitor classes: `ViolationCollectingVisitor`, `ViolationCollectingRewriter`, `CodeBlockVisitor`
- Core protocols: `Rule`, `SwiftSyntaxRule`, `ASTRule`
- Core model types used by every rule: `SwiftSource`, `RuleViolation`, `SyntaxViolation`, `Example`, `RuleOptions`, `SeverityOption`
- SwiftSyntax extensions from `Extensions/SwiftSyntax+*.swift`

## What stays in SwiftiomaticKit

- All 472 rule implementations (depend on SwiftiomaticSyntax)
- Configuration, SourceKit, Format, Suggest, Migration
- Generated files (LintPipeline, RuleRegistry)
- CLI-facing public API

## Why this helps

- Rule changes (the most common edit) only recompile the changed rule + relink
- swift-syntax compilation is cached behind SwiftiomaticSyntax — never recompiles unless swift-syntax version changes
- Single new target, not a full restructure

## Work required

- [x] Identify exact set of types/protocols to move (check what all 472 rules actually import)
- [x] Create `SwiftiomaticSyntax` target in Package.swift
- [x] Move files into `Sources/SwiftiomaticSyntax/`
- [x] Add `public`/`package` access to moved types (required by `InternalImportsByDefault`)
- [x] Update rule files to `import SwiftiomaticSyntax` instead of individual swift-syntax modules
- [x] Update GeneratePipeline if generated files need new imports
- [x] Verify build and tests pass (564/572 pass, 8 pre-existing failures)

## Related

- Parent issue for full module split: fwk-0kx



## Progress Notes (session 2026-04-11)

### Completed

1. **Package.swift**: Created `SwiftiomaticSyntax` target with swift-syntax deps + SourceKitC + SwiftBasicFormat. Updated SwiftiomaticKit to depend on SwiftiomaticSyntax instead of individual swift-syntax products. Updated test target.

2. **63 files moved to `Sources/SwiftiomaticSyntax/`**: Base types (File, StringView, Line, ByteCount, ByteRange, String+SourceKit), all core models, rule protocols (Rule, SwiftSyntaxRule, RuleOptions, CollectingRule), visitor base classes (ViolationCollectingVisitor, CodeBlockVisitor, BodyLengthVisitor, CommandVisitor, CommentLinesVisitor, EmptyLinesVisitor, TriviaLineCollector), Console, TypeResolver protocol, SwiftSyntax extensions, utility extensions.

3. **Split `SwiftSource+Cache.swift`**: Syntax-only caches (`syntaxTree`, `locationConverter`, `foldedSyntaxTree`, `commands`, `commentLines`, `emptyLines`) moved to `SwiftiomaticSyntax/SwiftSource+SyntaxCache.swift` with `SyntaxCache<T>` class (renamed from private `Cache<T>`). SourceKit caches (`response`, `structureDictionary`, `syntaxMap`) stay in SwiftiomaticKit. `invalidateSyntaxCaches()` / `clearSyntaxCaches()` in SwiftiomaticSyntax; `invalidateCache()` / `clearCaches()` in SwiftiomaticKit call through.

4. **Extracted `SwiftSyntaxRule.correct()`** to `SwiftiomaticKit/Extensions/SwiftSyntaxRule+Correct.swift` because it calls `file.write()` which depends on `invalidateCache()` (needs SourceKit cache access).

5. **Extracted SourceKit-dependent code** from `SwiftVersion.swift` to `SwiftiomaticKit/Extensions/SwiftVersion+SourceKit.swift`. Extracted `RuleViolation.toDiagnostic()` to `SwiftiomaticKit/Extensions/RuleViolation+Diagnostic.swift`.

6. **BodyLengthVisitor protocol change**: Replaced direct `SeverityLevelsConfiguration` reference with `SeverityLevelsBasedRuleOptions` protocol using `warningThreshold` / `errorThreshold` properties. Conformance extension added to `SeverityLevelsConfiguration` in SwiftiomaticKit.

7. **Access control**: Added `package` to all moved types, properties, methods, inits. Fixed `package import Foundation` / `package import SwiftSyntax` in files exposing those types in package API (required by `InternalImportsByDefault`). Added explicit `package init` to structs needing cross-module memberwise init.

8. **Import updates**: Bulk-replaced `import SwiftSyntax` -> `import SwiftiomaticSyntax` in ~314 rule files. Added `import SwiftiomaticSyntax` to ~241 other SwiftiomaticKit files. Updated test files. Removed unnecessary imports from pure-utility/SourceKit files.

9. **Moved `SourceRange+Contains.swift`** to SwiftiomaticSyntax (needed by `SwiftSyntax+TreeWalking.swift`).

### Remaining Work

1. **Build verification blocked** by xc-mcp output limit bug (a1a-m2j). Last successful partial build had only 1 error (SourceRange.contains - now fixed) + 1 warning. Current state likely builds but needs verification.

2. **Unused import warnings**: Many SwiftiomaticKit files received `import SwiftiomaticSyntax` that may not be needed. Causes warning flood that overwhelms xc-mcp output limit. Need to either fix the output limit or selectively remove unused imports.

3. **Test suite**: Not yet run. Tests need `import SwiftiomaticSyntax` where they reference moved types. Bulk replacement of `import SwiftSyntax` -> `import SwiftiomaticSyntax` already done in test files.

4. **Xcode project**: Needs target/group updates for new SwiftiomaticSyntax target and moved files.

5. **Incremental build verification**: After build succeeds, verify that changing a rule file doesn't recompile SwiftiomaticSyntax.

### Key Design Decisions

- `@_exported public import` for all swift-syntax modules in `Exports.swift` — consumers only need `import SwiftiomaticSyntax`
- `SyntaxCache<T>` class made `package` visible (was `private`) so SwiftiomaticKit can reuse it for SourceKit caches
- `SwiftSyntaxRule.correct()` kept in SwiftiomaticKit because it needs `file.write()` -> `invalidateCache()` -> SourceKit cache access
- `SeverityLevelsBasedRuleOptions` protocol abstracts away `SeverityLevelsConfiguration` so BodyLengthVisitor doesn't depend on concrete Kit type



### Session 2 (2026-04-12)

Build passes. 564/572 tests pass — 8 failures are pre-existing (StatementPositionRule, IdentifierNameRule, CommandTests, DisableAllTests — tracked in 0na-1xs).

Key fixes this session:
- Made ViolationCollectingVisitor, CodeBlockVisitor, BodyLengthVisitor, ViolationCollectingRewriter `open` for cross-module subclassing
- Made SyntaxViolation, ViolationMessage, SeverityLevelsBasedRuleOptions `public` (used in open class APIs)
- Added `public import SwiftiomaticSyntax` to files with public API using SwiftiomaticSyntax types
- Added `@testable import SwiftiomaticSyntax` to all test files
- Fixed SourceLocation ambiguity in SuggestTestHelpers (Testing vs SwiftSyntax)
- Added `import SwiftiomaticSyntax` to CLI target files

Remaining: commit, Xcode project update, verify incremental caching benefit.
