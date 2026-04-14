---
# f72-osd
title: Consolidate duplicated visitor patterns in rules
status: ready
type: task
priority: normal
created_at: 2026-04-14T02:42:23Z
updated_at: 2026-04-14T02:42:23Z
parent: kqx-iku
sync:
    github:
        issue_number: "268"
        synced_at: "2026-04-14T02:58:30Z"
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
- [ ] Extract shared doc-comment extraction helpers
- [ ] Evaluate consolidating multi-declaration visitors
- [ ] Verify with RuleExampleTests batch
