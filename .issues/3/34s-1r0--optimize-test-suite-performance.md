---
# 34s-1r0
title: Optimize test suite performance
status: completed
type: task
priority: high
created_at: 2026-03-01T01:24:37Z
updated_at: 2026-03-01T01:28:06Z
sync:
    github:
        issue_number: "108"
        synced_at: "2026-03-01T01:41:14Z"
---

Test suite takes too long to run. Key bottlenecks identified:

## Analysis

### Format Tests (2,624 `testFormatting` calls across 163 files)
Each call runs **4-6 format/lint passes**, including 2 passes with ALL ~140 rules:
1. `format(input, rules: [rule])` — single rule (fast)
2. `format(input, rules: FormatRules.all(except:))` — **ALL ~140 rules** (expensive)
3. `format(output, rules: [rule])` — idempotence (fast, conditional)
4. Per-rule disable command test (fast, conditional)
5. `lint(output, rules: [rule])` — lint single rule (fast)
6. `lint(output2, rules: FormatRules.all(except:))` — **ALL ~140 rules** (expensive)

**Result: ~5,248 "all rules" passes**, each applying ~130 rules iteratively until convergence.

### Lint Tests (379 `verifyRule` calls across 54 files + 250 generated tests)
Each call multiplies examples by ~4-6x:
- 3x base variants (normal + emoji + shebang) for all triggers + non-triggers
- Comment wrapping tests
- String wrapping tests
- Disable command tests (per identifier)
- Severity change tests
- Correction tests (with disk I/O) + their variants

### Input is re-tokenized redundantly
`testFormatting` tokenizes the same input string multiple times across its passes.

## Plan

- [x] Add env var `SWIFTIOMATIC_FAST_TESTS=1` to skip "all rules" interaction passes in `testFormatting`
- [x] Add env var support to skip variant tests (emoji, shebang, comment, string) in `verifyRule`
- [ ] Cache tokenization in `testFormatting` to avoid re-tokenizing the same input (deferred — minimal impact vs above)
- [x] Evaluate whether the "all rules" pass has ever caught real bugs to justify its cost (kept for CI, skipped locally)


## Results

| Metric | Normal | Fast Mode | Improvement |
|--------|--------|-----------|-------------|
| Test execution | 21s | 4.3s | **80% faster** |
| CPU time | 461s | 62s | **87% less CPU** |
| Wall clock (incl build) | 82s | 61s | **26% faster** |

Set `SWIFTIOMATIC_FAST_TESTS=1` for local development. CI runs full suite without the env var.
