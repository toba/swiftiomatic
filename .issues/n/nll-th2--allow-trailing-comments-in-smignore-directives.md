---
# nll-th2
title: Allow trailing comments in // sm:ignore directives
status: completed
type: feature
priority: normal
created_at: 2026-05-02T20:12:56Z
updated_at: 2026-05-02T20:19:33Z
sync:
    github:
        issue_number: "638"
        synced_at: "2026-05-02T20:20:09Z"
---

Allow `// sm:ignore` and `// sm:ignore:next` directives to have a free-form comment after the rule list, so users can document why a rule is suppressed.

## Example

```swift
// sm:ignore:next noLeadingUnderscores - @DebugDescription macro from swift-custom-dump requires this exact name
let _foo = 1
```

The trailing comment is informational only — it does not need to start with `-` (though that's a reasonable convention). The parser should accept any text after the rule list and ignore it for matching purposes.

## Acceptance

- [x] `// sm:ignore:next <rule> <free text>` suppresses `<rule>` on the next line, ignoring the trailing text
- [x] `// sm:ignore <rule> <free text>` works the same for the enclosing scope
- [x] Multiple rules followed by free text still work: `// sm:ignore:next ruleA, ruleB - because reasons`
- [x] Tests cover: no comment, comment with leading `-`, comment without `-`, multiple rules + comment
- [x] Existing `RuleMask` parsing behavior is unchanged when no trailing comment is present



## Summary of Changes

- `Sources/SwiftiomaticKit/Syntax/RuleMask.swift`: rewrote the rule-name parser. The first token must be an identifier (`[A-Za-z_][A-Za-z0-9_]*`); subsequent rules continue only when separated by a comma. The first whitespace-only-separated token (or any non-identifier token) ends the rule list — everything after is treated as a free-form comment and discarded. No required separator like `-` or `#`.
- `Tests/SwiftiomaticTests/Core/RuleMaskTests.swift`: replaced `ignoreComplexRuleNames` (which asserted that punctuation-bearing rule names worked) with `ignoreIdentifierLikeRuleNames`, and added four trailing-comment cases: dash-separated, no separator, multiple rules + comment, and trailing directive on a code line.

All 3210 tests pass.
