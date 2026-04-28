---
# 0we-lcr
title: Update DocC, README, list-rules / generate-docs for style model
status: ready
type: task
priority: normal
created_at: 2026-04-28T01:41:46Z
updated_at: 2026-04-28T01:41:46Z
parent: iv7-r5g
blocked_by:
    - ddi-wtv
sync:
    github:
        issue_number: "483"
        synced_at: "2026-04-28T02:40:01Z"
---

## Goal

Bring user-facing documentation and generator commands in line with the style-driven model from epic `iv7-r5g`.

## Tasks

- README: replace any rule-toggle examples with style-based configuration. Document `compact` as the only supported style, `roomy` as reserved.
- DocC: update `SwiftiomaticKit`'s Documentation.docc landing page and topics. Remove rule-by-rule pages; add a style overview.
- `sm list-rules` — decide between (a) rename to `sm list-findings` and emit the lint findings catalog, or (b) remove the subcommand entirely. Recommendation: (a).
- `sm generate-docs` — regenerate against the new model; remove generator paths that walked the old rule list.

## Verification

- README renders correctly; example configs are valid against the new schema.
- `xc-swift swift_diagnostics` clean.
- DocC build succeeds with no broken links.
