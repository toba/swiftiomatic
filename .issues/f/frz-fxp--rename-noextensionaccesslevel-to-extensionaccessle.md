---
# frz-fxp
title: Rename `NoExtensionAccessLevel` to `ExtensionAccessLevel`; rename `onDeclarations` to `onMembers`
status: completed
type: task
priority: normal
created_at: 2026-04-24T21:50:13Z
updated_at: 2026-04-24T21:54:46Z
sync:
    github:
        issue_number: "383"
        synced_at: "2026-04-24T22:30:45Z"
---

Rename rule class, file, config key, and placement enum case:
- `NoExtensionAccessLevel` → `ExtensionAccessLevel`
- `onDeclarations` → `onMembers`

- [x] Rename rule source file and class
- [x] Rename test file and struct
- [x] Update all source references
- [x] Update all test references
- [x] Regenerate schema and generated files
- [x] Build and test


## Summary of Changes

Renamed `NoExtensionAccessLevel` → `ExtensionAccessLevel` (class, file, config key). Renamed placement enum case `onDeclarations` → `onMembers`. Updated all source, test, and issue references. Regenerated schema.json and generated Swift files. All 20 rule tests pass.
