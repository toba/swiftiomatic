---
# 2sn-0al
title: 'Phase 4f: retarget test harness + verify'
status: ready
type: task
priority: high
created_at: 2026-04-28T15:50:30Z
updated_at: 2026-04-28T15:50:30Z
parent: ddi-wtv
blocked_by:
    - 49k-dtg
    - 95z-bgr
    - np6-piu
    - zvf-rsq
    - mn8-do3
sync:
    github:
        issue_number: "498"
        synced_at: "2026-04-28T16:43:51Z"
---

Phase 4f of `ddi-wtv` collapse plan: retarget the test harness at the compact pipeline and verify the full suite is green.

## Tasks

- Add `assertFormatting(rule:input:expected:findings:configuration:)` overload in `Tests/SwiftiomaticTests/Rules/LintOrFormatRuleTestCase.swift` that takes a rule name (string), constructs a `Configuration` with that single key enabled, runs `RewriteCoordinator` with `.useCompactPipeline` debug option set (or unconditionally if 4g already flipped default), and verifies output + findings.
- Migrate the ~120 rule test files from `assertFormatting(FooRule.self, ...)` to `assertFormatting(rule: "FooRule", ...)`. Mechanical sed-able rewrite. Some test files have helpers already; coordinate.
- Drop the legacy direct-instance branch (`formatType.init(context:)` + `formatter.visit(...)`) from `assertFormatting` — class shells are gone after 4a-4e.
- Run full test suite (`xc-swift swift_package_test`). Expect 3022+ passes.
- Run `Tests/SwiftiomaticPerformanceTests/RewriteCoordinatorPerformanceTests.swift` — confirm `testTwoStageCompactPipelineOnLayoutCoordinator` < 200 ms.
- Address any rule-specific test failures by either fixing the merged function or updating the test (case-by-case).

## Verification gates

- `xc-swift swift_diagnostics --build-tests` clean.
- `xc-swift swift_package_test` all green.
- `sm format Sources/` produces no diff (run from a clean build).
- Perf test < 200 ms on `LayoutCoordinator.swift`.

## Notes

- A handful of tests rely on multi-rule combinations (not single-rule isolation). For those, the new helper accepts an optional `additionalRules: [String]` to enable a small set.
