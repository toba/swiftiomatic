---
# sbt-nii
title: Convert BlankLinesBetweenImports to layout
status: completed
type: task
priority: normal
created_at: 2026-04-24T23:42:34Z
updated_at: 2026-04-24T23:54:13Z
parent: os4-95x
sync:
    github:
        issue_number: "390"
        synced_at: "2026-04-25T01:59:57Z"
---

Use the new per-break maxBlankLines to remove blank lines between consecutive imports in the layout system.

- [x] Add maxBlankLines: 0 to breaks between consecutive imports in `visitCodeBlockItemList`
- [x] Remove `Sources/SwiftiomaticKit/Syntax/Rules/BlankLines/BlankLinesBetweenImports.swift`
- [x] Convert tests to layout tests (5 pass)
- [x] Regenerate and test (2532 pass)
