---
# fkt-mgf
title: 'ddi-wtv-7: golden-corpus diff verification + perf gate'
status: ready
type: task
priority: normal
created_at: 2026-04-28T02:43:08Z
updated_at: 2026-04-28T02:43:08Z
parent: ddi-wtv
blocked_by:
    - ogx-lb7
sync:
    github:
        issue_number: "489"
        synced_at: "2026-04-28T02:56:06Z"
---

Run the golden-corpus diff harness from `m82-uu9` against the compact pipeline and resolve any unexpected drift.

## Tasks

- [ ] Configure golden-corpus harness with `style: compact` and run
- [ ] Resolve any output drift; expected drift is documented in 2kl-d04 sec 7
- [ ] Run `Tests/SwiftiomaticPerformanceTests/RewriteCoordinatorPerformanceTests.swift` against `LayoutCoordinator.swift` and confirm < 200 ms wall-clock under `-c release`
- [ ] Capture before/after timings in the issue body

## Done when

Golden corpus identical (or drift acknowledged); perf < 200 ms.
