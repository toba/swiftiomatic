---
# 81i-nlr
title: Doc-rule defaults audit
status: scrapped
type: task
priority: low
created_at: 2026-04-25T20:43:43Z
updated_at: 2026-04-25T22:03:52Z
parent: 0ra-lks
sync:
    github:
        issue_number: "422"
        synced_at: "2026-04-25T22:35:10Z"
---

Several documentation rules default to `.no` (off). Users won't discover opt-in rules by default — decide whether the public-API doc rules should default to `.warn`.

## Findings

- [ ] `Sources/SwiftiomaticKit/Rules/Comments/DocCommentSummary.swift:26, 28`
- [ ] `Sources/SwiftiomaticKit/Rules/Comments/ValidateDocumentationComments.swift:27`
- [ ] `Sources/SwiftiomaticKit/Rules/Comments/DocumentPublicDeclarations.swift`

## Decision
- [ ] Either flip defaults to `.warn`, or document the rationale for off-by-default
