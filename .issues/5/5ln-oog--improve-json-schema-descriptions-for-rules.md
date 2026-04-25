---
# 5ln-oog
title: Improve JSON schema descriptions for rules
status: completed
type: task
priority: normal
created_at: 2026-04-25T23:38:32Z
updated_at: 2026-04-25T23:51:31Z
sync:
    github:
        issue_number: "439"
        synced_at: "2026-04-25T23:53:21Z"
---

Drop description from $defs/ruleBase and $defs/lintOnlyBase so per-rule descriptions show up in IDE hovers, and thread doc comments through custom rule property extraction so sub-properties (placement, accessLevel, limit, etc.) get meaningful descriptions instead of formulaic 'propertyName Options: a, b.' text. Add /// doc comments to the ~25 rule config struct properties that need them.

Completed. See git diff for details.
