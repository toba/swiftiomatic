---
# mzu-e7j
title: Replace NSRegularExpression with Swift Regex
status: completed
type: task
priority: normal
created_at: 2026-02-28T18:32:40Z
updated_at: 2026-02-28T18:47:51Z
sync:
    github:
        issue_number: "58"
        synced_at: "2026-03-01T01:01:39Z"
---

Migrate all remaining NSRegularExpression usage to the modern RegularExpression struct wrapping Swift Regex. 7 phases: extend RegularExpression, migrate regex()/match(), migrate simple rules, capture-group rules, complex rules, escapedPattern callsites, delete dead code.
