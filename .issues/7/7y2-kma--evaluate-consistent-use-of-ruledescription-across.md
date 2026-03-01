---
# 7y2-kma
title: Evaluate consistent use of RuleDescription across SwiftLint and SwiftFormat-derived rules
status: in-progress
type: task
priority: normal
created_at: 2026-03-01T20:20:03Z
updated_at: 2026-03-01T20:26:02Z
sync:
    github:
        issue_number: "128"
        synced_at: "2026-03-01T21:06:26Z"
---

Audit the two rule systems (Rule protocol with RuleDescription vs FormatRule class) for consistency in how rule metadata is described, documented, and consumed. Identify gaps and recommend whether/how to unify.

- [x] Map the two metadata models
- [x] Identify field coverage gaps
- [x] Evaluate generate-docs coverage
- [x] Assess RuleCatalog bridge completeness
- [x] Write findings and recommendations

## Summary of Changes

Evaluation only — no code changes. Findings:

1. **Two separate metadata systems**: Rule uses RuleDescription struct (11 fields); FormatRule uses inline stored properties (help, examples, options). They don't share a type.
2. **RuleCatalog bridges them** at the query layer via Entry, but loses rich metadata.
3. **generate-docs excludes FormatRules** entirely — 130 rules get no documentation output.
4. **Naming mismatch**: Rules use snake_case identifiers, FormatRules use camelCase names.
5. **rationale field adopted by only 14/323 rules** — dead API surface.
6. **Recommendation**: Don't unify the types (different execution models). Instead: (a) extend generate-docs for FormatRules, (b) add a RuleMetadata protocol for the common interface, (c) normalize naming, (d) audit rationale adoption.
