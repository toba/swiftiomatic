---
# 9t2-w2r
title: Remove style configuration concept
status: completed
type: task
priority: normal
created_at: 2026-04-30T03:04:04Z
updated_at: 2026-04-30T03:22:59Z
sync:
    github:
        issue_number: "518"
        synced_at: "2026-04-30T03:34:39Z"
---

Delete style config key, Style enum, --style CLI flag, all style-driven language. Replace pipeline dispatch with unconditional compact pipeline call. Bump schema 7 to 8. No migration needed (never released).

Plan: /Users/jason/.claude/plans/fluttering-sauteeing-mitten.md

- [ ] Delete Sources/SwiftiomaticKit/Rules/Style.swift
- [ ] Delete Sources/SwiftiomaticKit/Configuration/Configuration+Style.swift
- [ ] Delete Tests/SwiftiomaticTests/API/StyleTests.swift
- [ ] RewriteCoordinator: drop validateStyleSupported call; replace style switch with single runCompactPipeline call
- [ ] LintCoordinator: drop validateStyleSupported call
- [ ] SwiftiomaticError: remove styleNotImplemented case and message
- [ ] ConfigurationOptions: delete --style option and ExpressibleByArgument conformance
- [ ] Frontend.swift: delete two style override blocks
- [ ] DumpConfiguration: delete style override block
- [ ] CompactSyntaxRewriter: update docstring (remove compact style wording)
- [ ] Context.swift: rewrite the shouldRewrite comment
- [ ] Configuration.swift: bump highestSupportedConfigurationVersion 7 to 8
- [ ] CLAUDE.md: strip style language (lines 57, 64, 78, 95)
- [ ] README.md: strip style language (lines 3, 9, 15, 21, 28)
- [ ] Regenerate: swift run Generator (schema.json + Generated files)
- [ ] Verify: clean compile, tests green, --style now errors, dump-configuration drops top-level style



## Summary of Changes

- Deleted three style-only files (Style.swift, Configuration+Style.swift, StyleTests.swift).
- Removed style-driven dispatch: RewriteCoordinator now calls runCompactPipeline directly; both coordinators no longer validate style.
- Removed styleNotImplemented from SwiftiomaticError.
- Removed --style CLI flag and three configuration override sites (Frontend x2, DumpConfiguration).
- Updated CompactSyntaxRewriter docstring and Context.shouldRewrite comment to reflect per-rule semantics.
- Bumped highestSupportedConfigurationVersion 7 to 8.
- Stripped style-driven language from CLAUDE.md, README.md, and the two sub-target READMEs.

## Notes

- ConfigurationRegistry+Generated.swift still has a StyleSetting line; the build plugin regenerates from rule sources on next build and drops it automatically.
- Schema.json regen via swift run Generator deferred (build/verify deferred per user).
- During the work the user reorganized rewriter files (Rewrites/ to Syntax/Rewriter/); RewriteCoordinator edits carried over. CompactSyntaxRewriter docstring update was applied to the file at its prior path before the move.
