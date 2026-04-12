---
# kli-m0h
title: Swift Testing misattributes failures in serialized parameterized tests
status: ready
type: bug
priority: low
created_at: 2026-04-12T20:54:57Z
updated_at: 2026-04-12T20:54:57Z
sync:
    github:
        issue_number: "234"
        synced_at: "2026-04-12T21:03:02Z"
---

## Problem

`RuleExampleTests` uses `@Suite(.serialized)` with a parameterized `@Test(arguments:)`. When any parameterized case fails, Swift Testing reports the failure under a different case's label (typically `identifier_name` since it's mid-alphabet).

This was confirmed during uye-na5 investigation: debug logs proved the failing rule was `prefixed_toplevel_constant` (later `redundant_backticks`, later `no_grouping_extension`), but every failure was reported as `(→ identifier_name)`.

## Impact

Misleading test output. Agents and developers waste time investigating the wrong rule.

## Possible Mitigations

1. **Apple bug report**: file with Swift Testing team (`swift-testing` repo)
2. **Workaround**: add the rule identifier to all `#expect` messages so the actual failing rule is visible in the truncated output regardless of misattribution
3. **Workaround**: split the single parameterized test into per-scope-letter suites to reduce the misattribution blast radius

Option 2 is cheapest and was partially done during the uye-na5 debug session (then reverted). Could be made permanent.
