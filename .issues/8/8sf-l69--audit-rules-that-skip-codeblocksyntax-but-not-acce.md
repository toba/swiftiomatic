---
# 8sf-l69
title: 'Audit: rules that skip `CodeBlockSyntax` but not `AccessorBlockSyntax`'
status: completed
type: bug
priority: high
created_at: 2026-04-12T20:54:23Z
updated_at: 2026-04-12T21:28:47Z
sync:
    github:
        issue_number: "235"
        synced_at: "2026-04-12T21:29:56Z"
---

## Problem

Three rules skip `CodeBlockSyntax` children to avoid walking into local scopes but don't also skip `AccessorBlockSyntax`. Computed property / subscript bodies use `AccessorBlockSyntax`, not `CodeBlockSyntax`, so declarations inside them are incorrectly treated as top-level.

This is the same bug fixed in `PrefixedTopLevelConstantRule` (uye-na5).

## Affected Rules

- `MissingDocsRule` — may flag doc comments inside computed property bodies
- `ExplicitACLRule` — may flag access control on local `let` bindings inside computed properties
- `ExplicitTopLevelACLRule` — may flag access control on local declarations inside computed properties

## Fix

Added structural `skipsNestedScopes: Bool` property to `ViolationCollectingVisitor` and `ViolationCollectingVisitorProtocol`. Setting a single flag skips all three scope types together — structurally impossible to forget one.

Pipeline support via `scopeSkipFlags` in generated `LintPipeline` mirrors the existing `skippableDeclarations` mechanism.

## Validation

All 1864 tests pass. Added computed-property non-triggering examples for MissingDocsRule and ExplicitTopLevelACLRule.


## Summary of Changes

- Added `skipsNestedScopes: Bool` to `ViolationCollectingVisitorProtocol` and `ViolationCollectingVisitor` with doc comments
- Added default `visit(_:)` overrides for `CodeBlockSyntax`, `AccessorBlockSyntax`, `ClosureExprSyntax` in base class (direct-walk path)
- Updated `PipelineEmitter` with `scopeSkipTypes` and `scopeSkipFlags` (pipeline path)
- Migrated 4 rules to use `skipsNestedScopes`: MissingDocsRule, ExplicitACLRule, ExplicitTopLevelACLRule, PrefixedTopLevelConstantRule
- Added non-triggering computed-property examples for MissingDocsRule and ExplicitTopLevelACLRule
- Regenerated `LintPipeline.generated.swift`
- Updated `/rule` skill documentation
