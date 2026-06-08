---
# ybo-p2t
title: 'Audit: LineLength should ignore macro declarations when configured'
status: scrapped
type: bug
priority: normal
created_at: 2026-06-08T19:41:55Z
updated_at: 2026-06-08T19:46:41Z
sync:
    github:
        issue_number: "726"
        synced_at: "2026-06-08T19:59:33Z"
---

Upstream SwiftLint fix (realm/SwiftLint #6760 307568d5, 2026-06-06) ignores macro declarations under the 'function' line_length setting.

Reference: ~/Developer/swiftiomatic-ref/SwiftLint/Source/SwiftLintBuiltInRules/Rules/Metrics/LineLengthRule.swift

Check Swiftiomatic's LineLength rule for analogous handling of macro decls.



## Reasons for Scrapping

Swiftiomatic's `LineLengthLimit` rule (Sources/SwiftiomaticKit/Rules/Metrics/LineLengthLimit.swift) is a simple global line-length limit operating line-by-line on raw source text. It has no per-declaration-kind configuration analogous to SwiftLint's `function`/`excluded_function_kinds` settings, so the upstream change (which only affects the `function`-kind path) does not apply.
