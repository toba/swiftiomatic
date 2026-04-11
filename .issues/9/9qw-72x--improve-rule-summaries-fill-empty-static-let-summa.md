---
# 9qw-72x
title: 'Improve rule summaries: fill empty static let summary fields'
status: ready
type: task
priority: normal
created_at: 2026-04-11T18:22:20Z
updated_at: 2026-04-11T18:22:20Z
sync:
    github:
        issue_number: "181"
        synced_at: "2026-04-11T18:44:01Z"
---

6+ rules have `static let summary = ""`. Fill them in with concise, useful descriptions.

Identified rules with empty summaries:
- `static_over_final_class`
- `non_overridable_class_declaration`
- `opening_brace`
- `contrasted_opening_brace`
- `number_separator`
- `unhandled_throwing_task`
- (scan for others)

## Tasks

- [ ] Find all rules with empty summary fields
- [ ] Write concise summaries for each
- [ ] Verify build passes
