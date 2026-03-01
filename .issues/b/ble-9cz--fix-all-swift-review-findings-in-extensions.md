---
# ble-9cz
title: Fix all swift-review findings in Extensions/
status: completed
type: task
priority: normal
created_at: 2026-03-01T03:00:37Z
updated_at: 2026-03-01T03:07:43Z
sync:
    github:
        issue_number: "115"
        synced_at: "2026-03-01T03:57:27Z"
---

Fix all findings from manual swift-review of Sources/Swiftiomatic/Extensions/:

## High Priority
- [x] 6a: O(n²) unique dedup — add Hashable-constrained O(n) overload
- [x] 2a: Any-typed array(of:) — document as ObjC boundary or type

## Medium Priority
- [x] 5b: static var → static let for constant sets
- [x] 7a: TreeWalkable → TreeWalking naming
- [x] 1a: Deduplicate ruleEnabled overloads (documented, not merged — different Location constructors)
- [x] 8b: Document vendored swift-algorithms copy

## Low Priority
- [x] 7b: Namespace free functions (expandPath → URL.expandingPath, stripMarkdown → .strippingMarkdown, parseCommaDelimitedList → .commaDelimitedItems; regex left as free function — 23 call sites)
- [x] 7c: Reconcile — renamed to removingCaseAwarePrefix (different semantics from deletingPrefix)
- [x] 6c: Pre-allocate edit distance matrix
- [x] 8c: Remove dead group(by:) method
- [x] 8a: expandPath alive (used in tests) — added URL.expandingPath wrapper


## Summary of Changes

Applied 10 fixes across 9 extension files:
- **HIGH**: O(n) Hashable-constrained `unique` overload with `@_disfavoredOverload` fallback; documented `Any` as intentional ObjC boundary
- **MEDIUM**: `static var` → `static let` for constant sets; `TreeWalkable` → `TreeWalking`; documented vendored swift-algorithms; clarified ruleEnabled MARK comment
- **LOW**: Namespaced 3 free functions with legacy wrappers; renamed `removingPrefix` → `removingCaseAwarePrefix`; pre-allocated edit distance matrix; removed dead `group(by:)`
