---
# dil-cew
title: 'ddi-wtv-8: delete legacy RewritePipeline shells; regen schema'
status: ready
type: task
priority: normal
created_at: 2026-04-28T02:43:08Z
updated_at: 2026-04-28T05:36:09Z
parent: ddi-wtv
blocked_by:
    - g6t-gcm
    - fkt-mgf
    - 7fp-ghy
sync:
    github:
        issue_number: "487"
        synced_at: "2026-04-28T16:43:50Z"
---

After verification (ddi-wtv-7) passes, remove the legacy code path.

## Tasks

- [ ] Delete the `extension RewritePipeline { func rewrite(_:) }` block from PipelineGenerator (rewrite section)
- [ ] Delete the now-unused `visit(_:)` overrides on each rule that's been ported to `static transform` (the `transform` fn becomes the only entry point)
- [ ] Regenerate `schema.json` via the Generator executable
- [ ] Update `Configuration` to remove the per-rule rewrite/lint matrix where it's no longer accessible
- [ ] Final test pass: full suite green

## Done when

Legacy `RewritePipeline.rewrite` code path is gone; only the compact path exists; tests green; `schema.json` regenerated.
