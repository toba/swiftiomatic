---
# puj-n2z
title: noMutableCapture flags assignment-only mutations of local vars
status: completed
type: bug
priority: normal
created_at: 2026-05-02T02:55:26Z
updated_at: 2026-05-02T03:44:26Z
sync:
    github:
        issue_number: "626"
        synced_at: "2026-05-02T03:44:32Z"
---

The rule flags writes to a local var from inside a closure (e.g. `var height = 0; layoutManager.enumerateTextLayoutFragments(...) { fragment in height = fragment.frame.maxY; return false }`).

This is wrong because:
1. The suggested fix `[height]` makes the captured value immutable — you cannot then assign to it. The fix is impossible to apply.
2. Pure-write captures don't have the snapshot footgun the rule is designed to catch (the footgun is reading a stale snapshot). Writing always mutates the original.
3. This is the textbook idiom for extracting a value via a non-escaping closure.

Fix: skip references that appear on the LHS of an assignment (InfixOperatorExpr with `=` / compound assignment operator) or as the operand of `&` inout. These cannot use `[name]` capture lists.

- [x] Add test reproducing the assignment-only false positive
- [x] Add test for compound assignment (`+=`, etc.)
- [x] Skip LHS-of-assignment references in ImplicitCaptureFinder
- [x] Verify full suite passes

## Summary of Changes

The fix grew well beyond the originally-described scope as more false-positive patterns surfaced via running the binary against `../thesis` and the IDE.

`Sources/SwiftiomaticKit/Rules/Closures/NoMutableCapture.swift`:

- `MutableVarNameCollector`: skip `var` decls with attributes (`@State`, `@Bindable`, `@Binding`, `@FocusState`, `@AppStorage`, …). These are property-wrapper bindings whose runtime semantics are reference-like, not the mutable-value snapshot footgun this rule targets.
- `ImplicitCaptureFinder`: skip references that are part of a member-access expression (covers `.member` access AND base-of-member-access patterns like `record.parent = x`, `values.append(...)`, `counter.next()`). `[name]` capture is impossible here (captured copy is immutable).
- `ImplicitCaptureFinder`: skip the base of a subscript call (`dict[k] = v`).
- `ImplicitCaptureFinder`: skip pure-write references — LHS of `=` / compound assignment (`+=`, `-=`, etc., excluding comparison ops), or the operand of `&` (inout).
- `isStoredInBinding` gate on `visit(ClosureExprSyntax)`: only flag closures stored in a `let`/`var` binding (`let closure = { ... }`). Inline closures passed as function arguments (`array.forEach { ... }`, `tags.contains { ... }`, `enumerateTextLayoutFragments { ... }`, view builders, etc.) execute synchronously and never observe a mutation that hasn't happened yet — there's no snapshot footgun to warn about.

`Tests/SwiftiomaticTests/Rules/NoMutableCaptureTests.swift`: added 9 new tests covering each false-positive class, plus `readAfterAssignmentStillFlagged` to assert the textbook footgun pattern still fires.
