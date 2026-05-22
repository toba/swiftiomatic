---
# mvr-huv
title: 'Fix DropRedundantEquatable removing custom == when stored property is inside #if block'
status: completed
type: bug
priority: normal
created_at: 2026-05-22T15:26:25Z
updated_at: 2026-05-22T15:28:23Z
sync:
    github:
        issue_number: "698"
        synced_at: "2026-05-22T15:30:23Z"
---

DropRedundantEquatable does not descend into IfConfigDeclSyntax (#if/#else) blocks when collecting stored properties or checking for non-Equatable types. A struct like TypeIdentifier with `#if DEBUG let base: Any.Type #endif` hides `base` from the rule, so it only sees `id`, matches the custom `static func ==` (which compares only id), and removes it — breaking compilation because synthesized Equatable cannot be generated for Any.Type.

- [x] Add failing test reproducing the #if-hidden stored property case
- [x] Make stored-property collection and non-Equatable detection descend into #if blocks (or bail)
- [x] Verify fix


## Summary of Changes

Added `expandedMembers(_:)` to `DropRedundantEquatable`, which flattens a member block including members nested inside `IfConfigDeclSyntax` (`#if`/`#elseif`/`#else`) clauses. Both `collectStoredPropertyNames` and `hasNonEquatableStoredProperty` now iterate the expanded list, so conditionally-compiled stored properties (e.g. `#if DEBUG let base: Any.Type`) are seen. This makes the rule either detect a property-count mismatch or a non-Equatable type and bail, instead of wrongly removing the custom `==`. Added regression test `conditionalCompilationStoredPropertyNotFlagged`. All 17 DropRedundantEquatableTests pass.
