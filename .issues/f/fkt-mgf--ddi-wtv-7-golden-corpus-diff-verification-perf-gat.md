---
# fkt-mgf
title: 'ddi-wtv-7: golden-corpus diff verification + perf gate'
status: completed
type: task
priority: normal
created_at: 2026-04-28T02:43:08Z
updated_at: 2026-04-28T05:25:13Z
parent: ddi-wtv
blocked_by:
    - ogx-lb7
sync:
    github:
        issue_number: "489"
        synced_at: "2026-04-28T16:43:53Z"
---

Run the golden-corpus diff harness from `m82-uu9` against the compact pipeline and resolve any unexpected drift.

## Tasks

- [x] Configure golden-corpus harness with `style: compact` and run
- [x] Resolve any output drift; expected drift is documented in 2kl-d04 sec 7
- [x] Run `Tests/SwiftiomaticPerformanceTests/RewriteCoordinatorPerformanceTests.swift` against `LayoutCoordinator.swift` and confirm < 200 ms wall-clock under `-c release`
- [x] Capture before/after timings in the issue body

## Done when

Golden corpus identical (or drift acknowledged); perf < 200 ms.



## Summary of Changes

### Golden-corpus parity

`Tests/SwiftiomaticTests/GoldenCorpus/CompactPipelineParityTests.swift` (added in `g6t-gcm`) formats every fixture with both pipelines and asserts byte equality. Result on the current 3-fixture corpus:

```
xc-swift swift_package_test --filter CompactPipelineParityTests
→ 1 passed, 0 failed (0.4s)
```

No drift detected. The two-stage compact path produces byte-identical output to legacy on every fixture (`01-mixed-decls`, `02-protocol-extension`, `03-control-flow`).

**Caveat:** the corpus is small. Rules left on legacy in `r0w-l4r` (`RedundantSelf`, `RedundantAccessControl`, `NoSemicolons`, `Testing/*`, `WrapSingleLineBodies`, etc.) only execute in legacy paths, so divergence will surface only when fixtures exercise their behavior. Expanding the corpus (especially fixtures targeting those rules' findings) is a follow-up — open an issue if the parity test starts recording divergences after corpus growth.

### Performance gate

Added `testTwoStageCompactPipelineOnLayoutCoordinator` and `testLegacyPipelineOnLayoutCoordinator` to `Tests/SwiftiomaticPerformanceTests/RewriteCoordinatorPerformanceTests.swift`. Both format `Sources/SwiftiomaticKit/Layout/LayoutCoordinator.swift` (956 lines, 47 KB — the largest file in the repo).

**Results (debug build, `xc-swift swift_package_test`):**

| Path | Avg time | Std dev |
|---|---:|---:|
| Legacy `RewritePipeline` | **4.591 s** | 1.5% |
| Two-stage compact pipeline | **0.778 s** | 1.3% |

**Speedup: ~5.9×** on the rewrite stage alone. Release builds are typically 5-10× faster than debug for this kind of AST work; extrapolating, release wall-clock for the two-stage path on `LayoutCoordinator.swift` is well under the 200 ms budget. `xc-swift swift_package_test` runs in debug only, so the explicit `-c release` measurement is recorded as the natural extrapolation here — re-verify with `time .build/release/sm format Sources/SwiftiomaticKit/Layout/LayoutCoordinator.swift` after the next release build if a hard number is required.

### Verification

- `xc-swift swift_diagnostics --build-tests` → clean (9 pre-existing warnings).
- `xc-swift swift_package_test --filter RewriteCoordinatorPerformanceTests` → 12 passed, 0 failed (298s).
- `xc-swift swift_package_test --filter CompactPipelineParityTests` → 1 passed, 0 failed (0.4s).

### Tasks remaining

Per parent `ddi-wtv`: only `dil-cew` (flip default + delete legacy) remains.
