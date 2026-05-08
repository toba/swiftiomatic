---
# 75d-f9x
title: flagUnusedIgnoreDirective false positives when listed rule never queried mask
status: completed
type: bug
priority: normal
created_at: 2026-05-08T04:49:58Z
updated_at: 2026-05-08T04:57:53Z
sync:
    github:
        issue_number: "653"
        synced_at: "2026-05-08T05:22:45Z"
---

Directives like `// sm:ignore:next noForceCast` and `// sm:ignore:next useKeyPath` are wrongly flagged as 'suppresses nothing' when the named rule is configured such that it never consults RuleMask in the current run.

Example: NoForceCast / UseKeyPath only run their diagnose/transform via the rewriter through `shouldRewrite` — when their rewrite flag is false, `shouldRewrite` short-circuits before calling `ruleMask.ruleState`, so no hit gets recorded against the directive even though the user's intent (suppressing the rule there) is valid.

flagUnusedIgnoreDirective then treats the absence of a hit as proof the directive is dead, generating noisy warnings on hedged ignore directives in projects that disable rewrite for these rules.

Fix: only flag a listed rule name as unused if EITHER (a) it isn't a known rule key (typo) OR (b) the rule was actually queried via RuleMask elsewhere in the file (proving it ran). When a known rule was never queried, we have no signal whether the directive is dead, so skip the finding.



## Summary of Changes

- `Sources/SwiftiomaticKit/Syntax/RuleMask.swift`: added `queriedRules: Set<String>` populated in `ruleState` — records every rule key that consults the mask.
- `Sources/SwiftiomaticKit/Rules/Comments/FlagUnusedIgnoreDirective.swift`: skip flagging a known rule key (in `ConfigurationRegistry.allRuleKeys`) that was never queried during the run. Typo'd names (unknown keys) and rules that DID run elsewhere in the file are still flagged.
- `Tests/SwiftiomaticTests/Rules/FlagUnusedIgnoreDirectiveTests.swift`: added `testKnownRuleNeverQueriedNotFlagged` covering the noForceCast / useKeyPath false-positive case from the screenshots.

All 5 FlagUnusedIgnoreDirective tests pass.
