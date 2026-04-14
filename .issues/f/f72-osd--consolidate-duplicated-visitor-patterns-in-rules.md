---
# f72-osd
title: Consolidate duplicated visitor patterns in rules
status: completed
type: task
priority: normal
created_at: 2026-04-14T02:42:23Z
updated_at: 2026-04-14T03:05:36Z
parent: kqx-iku
sync:
    github:
        issue_number: "268"
        synced_at: "2026-04-14T03:07:05Z"
---

Several rule files implement nearly identical SyntaxVisitor patterns that could be consolidated.

## 1. Documentation rules — duplicated doc extraction
Three rules implement similar documentation comment extraction and validation:
- `Sources/Swiftiomatic/Rules/ValidateDocumentationComments.swift` (lines 47-149)
- `Sources/Swiftiomatic/Rules/AllPublicDeclarationsHaveDocumentation.swift` (lines 27-97)
- `Sources/Swiftiomatic/Rules/BeginDocumentationCommentWithOneLineSummary.swift` (lines 35-115)

Extract shared documentation extraction into a helper utility.

## 2. Multi-declaration visitor boilerplate
Rules that visit many declaration types with identical logic per type:
- `TypeNamesShouldBeCapitalized.swift` — 7 similar `visit()` methods (lines 20-53)
- `AllPublicDeclarationsHaveDocumentation.swift` — 9 similar `visit()` methods
- `BeginDocumentationCommentWithOneLineSummary.swift` — 11 similar `visit()` methods

All call a single helper like `diagnoseMissingDocComment(DeclSyntax(...), ...)`. Could consolidate with a helper taking `DeclSyntaxProtocol`.

## 3. XCTest detection duplication
4 rules call `setImportsXCTest()` with identical setup:
- `NeverUseImplicitlyUnwrappedOptionals.swift:37`
- `NeverUseForceTry.swift:33`
- `AlwaysUseLowerCamelCase.swift:31`
- `NeverForceUnwrap.swift:32`

## Tasks
- [x] Extract shared doc-comment extraction helpers (already extracted: `DocumentationComment`, `DocumentationCommentText`)
- [x] Evaluate consolidating multi-declaration visitors (inherent swift-syntax limitation; no generic `visit(DeclSyntax)` on SyntaxVisitor)
- [x] Verify with RuleExampleTests batch


## Summary of Changes

Evaluated all three consolidation areas:

1. **Doc extraction**: Already extracted into shared `DocumentationComment` and `DocumentationCommentText` utilities. The per-rule visitor overrides are inherent swift-syntax boilerplate.
2. **Multi-declaration visitors**: `SyntaxVisitor` has no generic `visit(_ node: DeclSyntax)` — each syntax type requires its own override. The 1-line delegation methods are already minimal.
3. **XCTest detection**: Already centralized in `setImportsXCTest()`. The 3-line `visit(SourceFileSyntax)` per rule is the minimum.

No code changes needed — the shared helpers were already properly extracted.
