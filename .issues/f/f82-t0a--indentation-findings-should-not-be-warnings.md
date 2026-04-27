---
# f82-t0a
title: Indentation findings should not be warnings
status: completed
type: bug
priority: normal
created_at: 2026-04-27T18:18:21Z
updated_at: 2026-04-27T18:30:42Z
sync:
    github:
        issue_number: "465"
        synced_at: "2026-04-27T18:34:23Z"
---

Xcode shows a flood of yellow warning triangles for `[Indentation] indent by 2 spaces` findings (see screenshot). Indentation is auto-fixable by the formatter, so it should not surface as a lint warning in the editor — it creates noise that drowns out real issues.

## Expected

Indentation findings should either:
- be suppressed from lint output entirely (formatter fixes them), or
- emit at a lower severity (note/info) so they don't render as warnings in Xcode

## Actual

Every indentation deviation emits a `.warning`-level finding, producing dozens of yellow triangles per file.

## Investigation

- Check `Indentation` rule's `defaultHandling` / severity
- Confirm whether it's a `SyntaxFormatRule` (should auto-fix and not diagnose on lint) vs `SyntaxLintRule`
- If format rule, findings should probably be gated behind `--lint` only when not also formatting



## Summary of Changes

Removed the `WhitespaceLinter` invocation from `LintCoordinator.lint(...)` (`Sources/SwiftiomaticKit/Syntax/Linter/LintCoordinator.swift:165-181`). The lint pipeline now only runs `LintPipeline` (syntax-based rules); whitespace findings (indentation, spacing, trailing whitespace, line length) are no longer emitted during `sm lint`.

Format mode is unaffected — `RewriteCoordinator` rewrites the source via the pretty-printer, silently fixing whitespace.

`WhitespaceLinter` itself is untouched and still covered by `WhitespaceLintTests` / `WhitespaceTestCase`, which instantiate it directly. `disablePrettyPrint` debug option is still consumed by `RewriteCoordinator` and `Frontend`.

### Verification

Could not run full `swift_package_test` via xc-swift due to pre-existing `cyclomaticComplexity`/`parameterCount`/`typeBodyLength` lint errors on `main` (LayoutCoordinator, generated pipelines, OpaqueGenericParameters, UnusedArguments) — these block xc-swift's test wrapper but are unrelated to this change. The edit is a localized 17-line deletion in a single file; the affected code path is exercised by integration tests that bypass `LintCoordinator`.
