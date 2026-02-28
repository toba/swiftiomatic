---
# v20-de2
title: Remove support for analyzing Swift code earlier than 6.2
status: in-progress
type: task
priority: normal
created_at: 2026-02-28T00:13:29Z
updated_at: 2026-02-28T00:15:01Z
---

Swiftiomatic should only support analyzing, formatting, and linting Swift 6.2+ code. Remove all handling for earlier Swift language versions in the analysis targets.

This means:
- **Suggest module**: Remove any checks or logic that handles pre-6.2 Swift patterns (e.g. suggesting migrations TO Swift 6 features — if the code isn't already 6.2, it's out of scope)
- **Format module**: Remove SwiftFormat rules/options that only apply to pre-6.2 code (e.g. `--swiftversion` handling for older versions, rules gated on Swift version checks < 6.2)
- **Lint module**: Remove SwiftLint rules/configurations that target pre-6.2 code (e.g. deployment target checks for old versions, rules about legacy syntax that doesn't compile under 6.2)
- **CLI**: Remove any `--swift-version` flags or config options that allow selecting a version < 6.2; if a version flag remains, validate it's >= 6.2
- **Tests**: Update fixtures and test cases that use pre-6.2 syntax

## Rationale

Swiftiomatic is opinionated and forward-looking. Supporting old Swift versions adds complexity and noise. If the code being analyzed isn't Swift 6.2, it shouldn't be fed to this tool.

## TODO

- [ ] Audit Suggest checks for version-gated logic
- [ ] Audit Format rules for swift version checks (grep for `swiftVersion`, `SwiftVersion`)
- [ ] Audit Lint rules for version-gated behavior
- [ ] Remove or simplify CLI version flags
- [ ] Update tests and fixtures
- [ ] Update CLAUDE.md if needed
