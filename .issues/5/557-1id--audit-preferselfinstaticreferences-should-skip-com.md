---
# 557-1id
title: 'Audit: PreferSelfInStaticReferences should skip composition/existential and is/as operands'
status: scrapped
type: bug
priority: normal
created_at: 2026-06-08T19:41:55Z
updated_at: 2026-06-08T19:46:41Z
sync:
    github:
        issue_number: "727"
        synced_at: "2026-06-08T19:59:33Z"
---

Upstream SwiftLint fixes (realm/SwiftLint #6749 affa4fb8, #6765 16f6aed9) stop rewriting composition/existential types and is/as cast operands to Self in prefer_self_in_static_references.

Reference files:
- ~/Developer/swiftiomatic-ref/SwiftLint/Source/SwiftLintBuiltInRules/Rules/Style/PreferSelfInStaticReferencesRule.swift
- ~/Developer/swiftiomatic-ref/SwiftLint/Source/SwiftLintBuiltInRules/Rules/Style/PreferSelfInStaticReferencesRuleExamples.swift

If Swiftiomatic has an equivalent rule, audit it for the same false positives.



## Reasons for Scrapping

Swiftiomatic has no rule equivalent to SwiftLint's `prefer_self_in_static_references` that rewrites bare type-name references to `Self` in static contexts. The closest existing rule, `UseSelfNotTypeName` (Sources/SwiftiomaticKit/Rules/Idioms/UseSelfNotTypeName.swift), only converts `type(of: self)` → `Self`. No false-positive surface to fix; no port needed.
