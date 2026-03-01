---
# dln-l56
title: 'Gap analysis: analyze command vs swift-review skill'
status: completed
type: task
priority: normal
created_at: 2026-03-01T00:51:35Z
updated_at: 2026-03-01T00:52:25Z
sync:
    github:
        issue_number: "57"
        synced_at: "2026-03-01T01:01:41Z"
---

Identify all patterns the swift-review skill detects that the analyze command's rules do not yet cover.



## Summary of Changes

Completed gap analysis comparing swift-review skill's 8 analysis categories against swiftiomatic's rule implementations. Identified 25+ specific gaps where AST awareness would add value over the grep-based scanner. Top priorities: code duplication detection (§1), Sequence vs Collection over-constraint (§2), AsyncStream completeness checking (§4), and quadratic copy detection in loops (§6).
