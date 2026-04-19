---
# r0l-y3c
title: Co-locate layout rule config with TSC implementation
status: completed
type: task
priority: normal
created_at: 2026-04-19T16:42:31Z
updated_at: 2026-04-19T16:45:16Z
---

Move TokenStreamCreator methods that have a 1:1 relationship with a layout rule into the rule's file as an extension.

## Feasible (clean 1:1)
- [x] BeforeGuardConditions ← visitGuardStmt from TSC+ControlFlow.swift
- [x] SpacesAroundRangeFormationOperators ← shouldRequireWhitespace(around:) from TSC+ContextualBreaks.swift
- [x] IndentConditionalCompilationBlocks ← visitIfConfigClause from TSC+MembersAndBlocks.swift

## Not feasible (entangled)
- AroundMultilineExpressionChainComponents — inside recursive insertContextualBreaks
- ReflowMultilineStringLiterals — splits string literal handling across files
- RespectsExistingLineBreaks — inside large utility methods
- IndentBlankLines — inside extractLeadingTrivia


## Summary of Changes

Moved three TokenStreamCreator methods into their corresponding layout rule files:
- `visitGuardStmt` → BeforeGuardConditions.swift (from TSC+ControlFlow.swift)
- `shouldRequireWhitespace(around:)` → SpacesAroundRangeFormationOperators.swift (from TSC+ContextualBreaks.swift)
- `visitIfConfigClause` → IndentConditionalCompilationBlocks.swift (from TSC+MembersAndBlocks.swift)

Also removed unused `import SwiftOperators` from TSC+ContextualBreaks.swift.
