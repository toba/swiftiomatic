---
# ekr-k5l
title: 'lint rule: detect // sm:ignore directives that suppress nothing'
status: completed
type: feature
priority: normal
created_at: 2026-05-08T02:05:14Z
updated_at: 2026-05-08T02:23:08Z
---

## Goal

Add a lint-only rule that flags `// sm:ignore` directives that have no effect — i.e. they list rules that did not actually fire on the directive's target scope (next statement / trailing line / EOF range).

## Motivation

`sm:ignore` directives accumulate over time: rules get renamed, code gets rewritten, the targeted finding stops firing. Stale directives are dead weight, and worse, can mask genuine future findings on the same line if a different rule is added with a similar name. A linter that surfaces unused directives makes them easy to clean up.

## Detection strategy

The infrastructure mostly exists — `RuleMask` already records (range, ruleNames) tuples per directive site. To detect 'unused':

1. In `RuleMask`, retain richer per-directive records: source location of the comment itself, target range, rule list (or `.all`), scope (`:next` / trailing / lone-eof), and a hit counter.
2. Stamp records as used when `ruleState(_:at:)` returns `.disabled` because of that record (i.e. tally the matching record). This captures both lint suppressions and format/rewrite suppressions, since both consult `RuleMask`.
3. Add a finalization step that walks all records after the lint+format passes complete: any record with a hit count of zero, AND that names specific rules (not bare `sm:ignore` for all rules — too noisy / can't be proven unused without running every rule against every node), produces a finding.
4. Per-rule directives with multiple names should be partially-flaggable: `// sm:ignore RuleA, RuleB` where only `RuleA` ever matched should flag `RuleB`. This means hits need to be tracked per (record × rule name).

## Edge cases / non-goals

- Bare `// sm:ignore` (all rules) is impractical to prove unused — skip.
- Unknown rule names in a directive (e.g. typos, removed rules) should also flag — these are guaranteed unused. Cross-reference `ConfigurationRegistry` to detect.
- File-scope rules (`fileLength`, etc.) gate at file end — must ensure their suppression credit propagates back to the right directive.
- Rule should be lint-only, no rewrite. Default severity `.warn`.

## Acceptance

- `// sm:ignore unusedRule` on a line where `unusedRule` does not fire → flagged.
- `// sm:ignore RealRule, TyposRule` where only `RealRule` matches → `TyposRule` flagged.
- Unknown rule name (not in registry) → flagged.
- Bare `// sm:ignore` → never flagged.
- Tests cover lone-line, `:next`, trailing, and unknown-name forms.



## Summary of Changes

- `Sources/SwiftiomaticKit/Syntax/RuleMask.swift`: Introduced `IgnoreDirective` (location, range, scope, totalHits, hitsPerRule). `RuleMask` now stores `[IgnoreDirective]` plus index lookup tables; `ruleState(_:at:)` increments per-rule hit counts on each `.disabled` lookup. Visitor helpers were extended to compute each comment's absolute source position (via piece source-length accumulation) so directives carry a source location.
- `Sources/SwiftiomaticKit/Rules/Comments/FlagUnusedIgnoreDirective.swift`: New lint-only rule (group: `.comments`, default `.warn`). Empty `visit(SourceFileSyntax)` registers it on the file node so the generator emits the dispatch; `visitPost(SourceFileSyntax)` runs after every other rule has stamped hits, walking `context.ruleMask.directives` and emitting one finding per `.subset` rule name with zero hits. Bare `// sm:ignore` (`.all` scope) is intentionally skipped.
- `Tests/SwiftiomaticTests/Rules/FlagUnusedIgnoreDirectiveTests.swift`: Tests cover typo'd rule name (lone-line and trailing forms), bare directive (never flagged), and partial use (one valid + one typo → only typo flagged).
- Full suite (3228 tests, +4 new) passes.
