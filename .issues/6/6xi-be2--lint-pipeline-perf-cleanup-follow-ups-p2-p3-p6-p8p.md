---
# 6xi-be2
title: Lint pipeline perf & cleanup follow-ups (P2, P3, P6, P8–P14, C1, C2, C4, N1–N5, M1, M2, M4)
status: ready
type: epic
priority: high
created_at: 2026-04-30T15:57:04Z
updated_at: 2026-04-30T15:57:04Z
sync:
    github:
        issue_number: "536"
        synced_at: "2026-04-30T16:27:52Z"
---

Follow-up tracker for deferred items from issue 2s8-oze (lint pipeline review). Each child captures one deferred finding with the potential performance benefit and the specific reason it was not landed in the first pass.

Parent review: 2s8-oze (status: review).

The high-leverage, lower-risk items (P1, P4, P5, P7, C3, M3, M5) shipped under 2s8-oze. Everything tracked here was intentionally deferred so it can land with its own measurements, generator changes, schema bumps, or coordinated refactors.

## Order-of-operations notes

- P3 depends on P1 already landed and benefits from generator changes — recommend pairing with P9.
- P9/P10 are large refactors; consider sequencing P9 first (typed dispatch table) before P10 (value-type rules).
- P2 should pair with P3 since both touch the dispatcher generation.
- M2 bumps the cache schema; pair with N2 if doing both to avoid two consecutive cache invalidations.
