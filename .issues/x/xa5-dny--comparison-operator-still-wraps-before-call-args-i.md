---
# xa5-dny
title: Comparison operator still wraps before call args in if-condition
status: ready
type: bug
priority: normal
created_at: 2026-04-30T05:39:21Z
updated_at: 2026-04-30T05:39:21Z
sync:
    github:
        issue_number: "531"
        synced_at: "2026-04-30T05:51:02Z"
---

Follow-up to 8yg-tvu. The comparison-operator break-precedence fix (gated to operands containing a function call) works for assignment context (`x = f(...) != 0`) but does NOT yet fix the same pattern inside an `if` condition: `if foo(bar: x, qux: y) == expected { ... }` still wraps as `if foo(\n  bar: x, qux: y)\n  == expected\n{ ... }` with `==` dangling on its own line, instead of the desired `if foo(\n  bar: x,\n  qux: y) == expected\n{ ... }`. Likely cause: the if-condition layout adds its own wrapping group (around the condition or before the `{` brace) that interferes with the comparison-operator open/close group's chunk bounding. Pinned by the existing test `comparisonOperatorYieldsToFunctionCallInCondition` in BinaryOperatorExprTests.swift — that test currently asserts the buggy output. When fixed, update its expected output to put each call argument on its own line.
