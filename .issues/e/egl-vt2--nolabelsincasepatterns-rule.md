---
# egl-vt2
title: NoLabelsInCasePatterns rule
status: completed
type: task
priority: normal
created_at: 2026-04-12T23:57:19Z
updated_at: 2026-04-13T00:11:31Z
parent: shb-etk
sync:
    github:
        issue_number: "242"
        synced_at: "2026-04-13T00:25:21Z"
---

Remove redundant labels in case patterns where the label matches the bound variable name.

**swift-format reference**: `NoLabelsInCasePatterns.swift` in `~/Developer/swiftiomatic-ref/`

Triggers:
```swift
switch value {
case .foo(bar: bar, baz: baz):    // ← labels redundant
    break
}
```

Preferred:
```swift
switch value {
case .foo(bar, baz):
    break
}
```

`empty_enum_arguments` handles `case .foo(_)` → `case .foo` but not redundant labels.

## Checklist

- [x] Decide scope: lint+correctable
- [x] Read reference implementation in swift-format
- [x] Create rule file with id `no_labels_in_case_patterns`
- [x] Detect case patterns where argument label matches the bound variable name
- [x] Handle per-argument (flags each redundant label individually)
- [x] Preserve labels where they differ from the bound name
- [x] Implement correction: remove redundant `label:` prefix
- [x] Handle tuple patterns and nested patterns
- [x] Add non-triggering and triggering examples
- [x] Run `swift run GeneratePipeline`
- [x] Verify examples pass via RuleExampleTests


## Summary of Changes

Created `NoLabelsInCasePatternsRule` (lint, correctable) at `Rules/Redundancy/Syntax/`. Uses visitor-based corrections — each redundant label is flagged and corrected independently.
