---
# 4a2-6wt
title: Simplify rule protocol hierarchy
status: completed
type: task
priority: normal
created_at: 2026-03-03T01:59:32Z
updated_at: 2026-03-03T02:13:21Z
sync:
    github:
        issue_number: "160"
        synced_at: "2026-03-03T02:20:31Z"
---

Consolidate 12 rule protocols down to 7 by deleting dead/redundant protocols.

## Phases
- [x] Phase 1: Delete dead protocols (OptInRule, SyntaxOnlyRule)
- [x] Phase 2: Absorb SwiftSyntaxCorrectableRule into SwiftSyntaxRule
- [x] Phase 3: Absorb CorrectableRule into Rule
- [x] Phase 4: Remove AnalyzerRule and CollectingRuleMarker
- [x] Phase 5: Regenerate lint pipeline
- [x] Phase 6: Verify build and tests pass


## Summary of Changes

Simplified the rule protocol hierarchy from 12 protocols to 7 by:

- **Deleted 6 protocols**: `OptInRule`, `SyntaxOnlyRule`, `CorrectableRule`, `SwiftSyntaxCorrectableRule`, `CollectingRuleMarker`, `AnalyzerRule`
- **Absorbed** `SwiftSyntaxCorrectableRule` into `SwiftSyntaxRule` (makeRewriter + correct logic + ViolationCollectingRewriter)
- **Absorbed** `CorrectableRule` into `Rule` (correct methods with defaults returning 0)
- **Absorbed** `AnalyzerRule` marker — rules just set `requiresCompilerArguments = true`
- **Removed** `CollectingRuleMarker` — `CollectingRule` extends `Rule` directly, auto-sets `isCrossFile = true`
- **Added** `canEnrichAsync` default on `AsyncEnrichableRule`
- **Updated** all dispatch sites to use static booleans instead of protocol type checks
- **Updated** ~120 rule files, test mocks, CLI files, pipeline generator
- Regenerated lint pipeline
- All tests pass
