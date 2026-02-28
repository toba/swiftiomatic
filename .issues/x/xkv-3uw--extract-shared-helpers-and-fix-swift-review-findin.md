---
# xkv-3uw
title: Extract shared helpers and fix swift-review findings
status: completed
type: task
priority: normal
created_at: 2026-02-28T02:15:44Z
updated_at: 2026-02-28T02:33:58Z
---

Implement the swift-review fixes plan:
- [ ] Extract shared helpers from check/rule pairs (~7 new files, ~14 files modified)
- [ ] Remove overlapping detections (AgentReviewCheck, Swift62ModernizationCheck)
- [ ] Typed throws for JSONFormatter
- [ ] sorted().first → max() in Inference.swift
- [ ] Add Sendable to Format enums, remove @unchecked from FormatOptions
- [ ] weak var → weak let in Formatter.swift


## Summary of Changes

Extracted 7 shared helper files from 7 check/rule pairs, eliminating ~1,500 lines of duplicated detection logic:

1. **TaskDetectionHelpers** — isReturned, isAssigned, EnclosingScope, TaskFinder
2. **ThrowCollector** — shared SyntaxVisitor for typed throws detection
3. **MutationDuringIterationFinder** — shared mutation-during-iteration visitor
4. **AnyTypeHelpers** — AnyTypeMatch enum and classifyAnyType()
5. **NamingHelpers** — assertion prefixes, factory method suggestions, action verb lists
6. **ConcurrencyDetectionHelpers** — completion handler, DispatchQueue, @unchecked Sendable detection
7. **SwiftUIContainerHelpers** — container sets, 4 layout check methods returning LayoutIssue

Also:
- Removed fire-and-forget Task detection from AgentReviewCheck (handled by FireAndForgetTaskCheck)
- Removed withObservationTracking from Swift62ModernizationCheck (handled by ObservationPitfallsCheck)
- Changed sorted().first to max() in Format/Inference.swift
- Changed weak var to weak let in Format/Formatter.swift (SE-0481)
- Skipped typed throws for JSONFormatter (JSONEncoder.encode throws untyped)
- Skipped Sendable for Format enums (FormatOptions uses closures in property types)
