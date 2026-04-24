---
# gcs-5eq
title: Fix camelCase key generation for acronym-prefixed rule names
status: completed
type: bug
priority: normal
created_at: 2026-04-24T15:22:59Z
updated_at: 2026-04-24T22:03:33Z
sync:
    github:
        issue_number: "367"
        synced_at: "2026-04-24T22:30:44Z"
---

Rule key generation produces incorrect camelCase when a rule name begins with an acronym. For example, `URLMacro` becomes `uRLMacro` instead of the correct `urlMacro`.

The fix should lowercase the leading acronym run (all uppercase letters before the first lowercase letter, keeping the last uppercase as part of the next word).

Examples:
- `URLMacro` → `urlMacro` (not `uRLMacro`)
- `HTTPHeader` → `httpHeader` (not `hTTPHeader`)
- `BlankLines` → `blankLines` (unchanged, already correct)

## Plan

- [x] Find the key generation code
- [x] Fix with regex to handle leading acronyms
- [ ] Verify existing rule keys are unaffected or corrected
