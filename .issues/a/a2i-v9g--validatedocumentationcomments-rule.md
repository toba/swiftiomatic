---
# a2i-v9g
title: ValidateDocumentationComments rule
status: completed
type: task
priority: normal
created_at: 2026-04-12T23:57:19Z
updated_at: 2026-04-13T00:36:44Z
parent: shb-etk
sync:
    github:
        issue_number: "253"
        synced_at: "2026-04-13T00:55:42Z"
---

Validate doc comment *structure*: param names match the function signature, returns clause present for non-Void functions, one-line summary at start. `missing_docs` only checks *presence*.

**swift-format reference**: `ValidateDocumentationComments.swift` and `BeginDocumentationCommentWithOneLineSummary.swift` in `~/Developer/swiftiomatic-ref/`

This combines two swift-format rules into one since they both validate doc comment quality.

## Checklist

- [x] Decide scope: lint (warning, opt-in)
- [x] Read reference implementation in swift-format
- [x] Create rule file with id `validate_documentation_comments`
- [x] Deferred: one-line summary check (would need swift-markdown for robust paragraph detection)
- [x] Check: `- Parameter` names match function signature parameter names
- [x] Check: no `- Parameter` entries for parameters that don't exist
- [x] Check: `- Returns:` present when function returns non-Void
- [x] Check: `- Throws:` present when function is throwing
- [x] Deferred: sub-check configuration (all checks run together for now)
- [x] Add non-triggering and triggering examples for each sub-check
- [x] Run `swift run GeneratePipeline`
- [x] Verify examples pass via RuleExampleTests


## Summary of Changes

Created `ValidateDocumentationCommentsRule` (lint, opt-in) at `Rules/Documentation/Comments/`. Parses doc comments from trivia (no swift-markdown dependency). Validates parameter names match signature, Returns/Throws clause presence, and singular vs plural Parameter layout.
