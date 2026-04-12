---
# zry-7cz
title: 'Generator: detect pipeline-ineligible rules automatically'
status: ready
type: task
priority: normal
created_at: 2026-04-12T20:54:39Z
updated_at: 2026-04-12T20:54:39Z
sync:
    github:
        issue_number: "233"
        synced_at: "2026-04-12T21:03:02Z"
---

## Problem

The pipeline generator routes all `SwiftSyntaxRule` conformers through the single-pass pipeline by default. Rules that override `validate(file:)` with post-processing logic (cross-referencing visitor data after the walk) produce 0 violations in the pipeline because the pipeline only reads the visitor's `violations` array.

Currently the workaround is a manual `static let requiresPostProcessing = true` flag (added for `NoGroupingExtensionRule` in uye-na5). This is fragile — easy to forget when creating a new rule.

## Desired Behavior

The generator should detect this automatically. Possible approaches:

1. **AST analysis in the generator**: check if any visitor class appends to `violations` in its `visit`/`visitPost` overrides. If not, it's a post-processing rule.
2. **Runtime check**: after pipeline walk, if a rule produced 0 pipeline violations but `validate(file:)` produces violations, warn or fall back.
3. **Convention**: require all pipeline rules to put violation logic in the visitor, not in `validate`. Document this as a rule authoring constraint.

Option 3 is simplest and most maintainable. The `requiresPostProcessing` flag serves as the escape hatch for rules that can't follow the convention.

## Current Rules Using Post-Processing

- `NoGroupingExtensionRule` (already marked)

Scan for others that override `validate(file:)` on `SwiftSyntaxRule` conformers — see uye-na5 investigation notes.
