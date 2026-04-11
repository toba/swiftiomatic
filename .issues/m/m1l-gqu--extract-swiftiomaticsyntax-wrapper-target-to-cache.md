---
# m1l-gqu
title: Extract SwiftiomaticSyntax wrapper target to cache swift-syntax builds
status: ready
type: task
priority: normal
created_at: 2026-04-11T23:08:04Z
updated_at: 2026-04-11T23:08:04Z
parent: fwk-0kx
sync:
    github:
        issue_number: "202"
        synced_at: "2026-04-11T23:48:40Z"
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

- [ ] Identify exact set of types/protocols to move (check what all 472 rules actually import)
- [ ] Create `SwiftiomaticSyntax` target in Package.swift
- [ ] Move files into `Sources/SwiftiomaticSyntax/`
- [ ] Add `public`/`package` access to moved types (required by `InternalImportsByDefault`)
- [ ] Update rule files to `import SwiftiomaticSyntax` instead of individual swift-syntax modules
- [ ] Update GeneratePipeline if generated files need new imports
- [ ] Verify full test suite passes

## Related

- Parent issue for full module split: fwk-0kx
