---
# a2i-v9g
title: ValidateDocumentationComments rule
status: ready
type: task
priority: normal
created_at: 2026-04-12T23:57:19Z
updated_at: 2026-04-12T23:57:19Z
parent: shb-etk
sync:
    github:
        issue_number: "253"
        synced_at: "2026-04-13T00:25:22Z"
---

Validate doc comment *structure*: param names match the function signature, returns clause present for non-Void functions, one-line summary at start. `missing_docs` only checks *presence*.

**swift-format reference**: `ValidateDocumentationComments.swift` and `BeginDocumentationCommentWithOneLineSummary.swift` in `~/Developer/swiftiomatic-ref/`

This combines two swift-format rules into one since they both validate doc comment quality.

## Checklist

- [ ] Decide scope: lint (warning) or suggest (agent-only)
- [ ] Read both reference implementations in swift-format
- [ ] Create rule file with id `validate_documentation_comments`
- [ ] Check: doc comment begins with a one-line summary (no blank first line, first paragraph is single sentence)
- [ ] Check: `- Parameter` names match function signature parameter names
- [ ] Check: no `- Parameter` entries for parameters that don't exist
- [ ] Check: `- Returns:` present when function returns non-Void
- [ ] Check: `- Throws:` present when function is throwing (optional/configurable)
- [ ] Consider making sub-checks individually configurable via options
- [ ] Add non-triggering and triggering examples for each sub-check
- [ ] Run `swift run GeneratePipeline`
- [ ] Verify examples pass via RuleExampleTests
