---
# v2g-exw
title: Add SPM command plugins for Format and Lint
status: completed
type: feature
priority: normal
created_at: 2026-03-02T23:57:46Z
updated_at: 2026-03-02T23:59:30Z
sync:
    github:
        issue_number: "142"
        synced_at: "2026-03-02T23:59:46Z"
---

Add CommandPlugin + XcodeCommandPlugin targets so consumers can invoke formatting/linting from Xcode's navigator and `swift package plugin`.

## Tasks
- [x] Create Plugins/FormatPlugin/plugin.swift
- [x] Create Plugins/LintPlugin/plugin.swift
- [x] Update Package.swift with plugin products and targets
- [x] Verify build compiles

## Summary of Changes

Added two SPM command plugins (FormatPlugin and LintPlugin) that shell out to the swiftiomatic executable. Both support CommandPlugin (SPM CLI) and XcodeCommandPlugin (Xcode navigator right-click). Format uses `sourceCodeFormatting()` intent; Lint uses a custom `lint-source-code` verb invoking `swiftiomatic analyze --format xcode`.
