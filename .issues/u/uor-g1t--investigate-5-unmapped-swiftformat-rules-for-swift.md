---
# uor-g1t
title: Investigate 5 unmapped SwiftFormat rules for Swiftiomatic equivalents
status: completed
type: task
priority: normal
created_at: 2026-04-11T23:49:49Z
updated_at: 2026-04-12T21:40:32Z
sync:
    github:
        issue_number: "203"
        synced_at: "2026-04-12T21:41:30Z"
---

Five SwiftFormat rules have no Swiftiomatic equivalent and show as unmapped during `sm migrate`. Investigate whether each warrants a new rule, maps to an existing one, or should remain unmapped.

## Unmapped Rules

- [x] `consistentSwitchCaseSpacing` — ensures consistent blank lines between switch cases. Related to `vertical_whitespace_between_cases` but may differ in behavior.
- [x] `wrapFunctionBodies` — wraps/unwraps function bodies based on length. Related to `single_line_body` but may cover more cases.
- [x] `wrapLoopBodies` — wraps/unwraps loop bodies based on length. Same family as `wrapFunctionBodies`.
- [x] `wrapPropertyBodies` — wraps/unwraps computed property bodies. Same family.
- [x] `wrapSingleLineComments` — wraps comments that exceed max line width.

## Investigation Steps

For each rule:
1. Check SwiftFormat ref at `~/Developer/swiftiomatic-ref/SwiftFormat` for exact behavior
2. Check if an existing Swiftiomatic rule already covers it (possibly under a different name)
3. If no equivalent exists, assess whether it's worth adding
4. If it maps to an existing rule, add the mapping to `RuleMapping.swiftformatMapping`


## Findings

### 1. `consistentSwitchCaseSpacing` → **map to `vertical_whitespace_between_cases`**

**SwiftFormat behavior:** Uses majority-vote to enforce consistency — if most cases in a switch have blank lines between them, it adds blank lines to all; if most don't, it removes them from all.

**Swiftiomatic equivalent:** `VerticalWhitespaceBetweenCasesRule` — enforces a deterministic style (`separation: always` or `separation: never`) rather than majority-vote consistency.

**Verdict:** Map it. Swiftiomatic's rule is the direct equivalent — it covers the same concern (vertical spacing between switch cases) with a more deterministic approach. The majority-vote behavior is a stylistic choice that Swiftiomatic intentionally replaces with explicit configuration. Users migrating from SwiftFormat will get the same domain covered.

### 2. `wrapFunctionBodies` → **intentionally unmapped (inverse of existing rule)**

**SwiftFormat behavior:** Expands single-line function/init/subscript bodies onto multiple lines unconditionally.

**Swiftiomatic equivalent:** `SingleLineBodyRule` does the **opposite** — collapses single-statement multiline bodies onto one line when they fit within `max_width`. These are inverse operations.

**Verdict:** Leave unmapped and add to `swiftformatRemoved` with explanation. Swiftiomatic's philosophy favors collapsing short bodies (via `SingleLineBodyRule`), not expanding them. Migrating users who want expansion behavior would need to disable `single_line_body` instead.

### 3. `wrapLoopBodies` → **intentionally unmapped (same family as wrapFunctionBodies)**

**SwiftFormat behavior:** Expands single-line loop bodies (for, while, repeat) onto multiple lines.

**Swiftiomatic equivalent:** `SingleLineBodyRule` covers loops too (collapses them, inverse behavior).

**Verdict:** Same as `wrapFunctionBodies` — add to `swiftformatRemoved`. Same rationale.

### 4. `wrapPropertyBodies` → **intentionally unmapped (same family)**

**SwiftFormat behavior:** Expands single-line computed property and accessor bodies onto multiple lines.

**Swiftiomatic equivalent:** `SingleLineBodyRule` covers computed properties too.

**Verdict:** Same as above — add to `swiftformatRemoved`.

### 5. `wrapSingleLineComments` → **genuinely unmapped, candidate for new rule**

**SwiftFormat behavior:** Wraps `//` and `///` comments that exceed `maxWidth` by breaking at word boundaries, preserving prefix and indentation.

**Swiftiomatic equivalent:** None. `LineLengthRule` can flag long lines but doesn't rewrite comments. `CommentSpacingRule` only checks spacing after `//`. No rule wraps comments.

**Verdict:** Leave unmapped for now. This would be a new `.format` scope rule. Worth adding eventually — comment wrapping is a common formatting concern — but it's not blocking migration since `LineLengthRule` will still flag the long lines.

## Recommended Actions

- [x] Add mapping: `consistentSwitchCaseSpacing` → `vertical_whitespace_between_cases` in `RuleMapping.swiftformatMapping` — deferred to a9u-qgt audit
- [x] Add to `swiftformatRemoved`: `wrapFunctionBodies`, `wrapLoopBodies`, `wrapPropertyBodies` — deferred to a9u-qgt audit
- [x] `wrapSingleLineComments` — deferred; low priority, no blocking migration impact
- [x] Keep `wrapSingleLineComments` as unmapped in migration output until rule is implemented


## Summary of Changes

Investigation complete for all 5 unmapped rules. Remaining code changes (adding mapping entries) deferred to audit epic a9u-qgt (#229).
