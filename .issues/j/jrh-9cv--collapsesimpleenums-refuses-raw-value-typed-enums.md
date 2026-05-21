---
# jrh-9cv
title: CollapseSimpleEnums refuses raw-value-typed enums that assign no raw values
status: completed
type: bug
priority: normal
created_at: 2026-05-21T22:23:56Z
updated_at: 2026-05-21T22:25:57Z
sync:
    github:
        issue_number: "693"
        synced_at: "2026-05-21T22:26:37Z"
---

CollapseSimpleEnums.isCollapsible rejects any enum whose inheritance clause names a known raw-value type (String, Int, ...) even when no case assigns an explicit raw value. So:

```swift
enum ObjectType: String, SQLiteType {
    case table, index, view, trigger
}
```

is left expanded, though collapsing to a single line is lossless:

```swift
enum ObjectType: String, SQLiteType { case table, index, view, trigger }
```

The element-level check already rejects cases with explicit raw values (`element.rawValue != nil`). The blanket inheritance-type guard is redundant for safety and should be dropped/narrowed so collapse proceeds when no case assigns a raw value.

## Tasks
- [x] Add failing test: raw-value-typed enum with no assigned raw values collapses
- [x] Add test: enum with an assigned raw value is still left expanded (skipsRawValues retained)
- [x] Remove/narrow the rawValueTypes inheritance guard in isCollapsible
- [x] Confirm filtered tests pass (16 passed)

## Summary of Changes

Dropped the `rawValueTypes` inheritance guard (and the now-unused set) from `CollapseSimpleEnums.isCollapsible`. Collapse now proceeds for raw-value-typed enums (`: String`, `: Int`, ...) as long as no case assigns an explicit raw value — the element-level `element.rawValue != nil` check still blocks those. `enum ObjectType: String, SQLiteType { case table, index, view, trigger }` now collapses onto one line.

Flipped the former `skipsRawValueTypeEnum` test to `collapsesRawValueTypeEnumWithoutAssignments` and added `collapsesRawValueTypeEnumWithExtraConformance` for the reported example. `skipsRawValues` (explicit `= 0`) still asserts expansion. 16/16 CollapseSimpleEnumsTests pass.

Scope: enum-only by nature.
