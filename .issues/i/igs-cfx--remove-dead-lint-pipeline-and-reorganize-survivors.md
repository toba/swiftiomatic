---
# igs-cfx
title: Remove dead Lint/ pipeline and reorganize survivors
status: completed
type: task
priority: normal
created_at: 2026-02-28T21:18:07Z
updated_at: 2026-02-28T21:21:23Z
---

- [x] Extract Duration.timeInterval to Extensions/Duration+TimeInterval.swift
- [x] Extract filteringCompilerArguments to Extensions/Array+CompilerArguments.swift
- [x] Move SwiftPMCompilationDB to SourceKit/, patch FilePath/CompilerArguments
- [x] Delete dead files (10 Lint/ files + 2 Config files + 1 test file)
- [x] Delete empty Lint/ folder
- [x] Verify swift build succeeds (no new errors; pre-existing Format/ errors unchanged)
- [x] Verify no references to deleted types remain


## Summary of Changes

Removed ~1,658 lines of dead Lint/ pipeline code. Extracted 2 live extensions to new files, moved SwiftPMCompilationDB to SourceKit/, deleted 12 dead files and the empty Lint/ directory. Build has only pre-existing errors from Format/ refactoring (not introduced by this change).
