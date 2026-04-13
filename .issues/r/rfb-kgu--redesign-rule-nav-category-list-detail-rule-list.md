---
# rfb-kgu
title: 'Redesign rule nav: category list → detail rule list'
status: review
type: feature
priority: high
created_at: 2026-04-13T16:22:50Z
updated_at: 2026-04-13T16:35:43Z
sync:
    github:
        issue_number: "259"
        synced_at: "2026-04-13T16:41:18Z"
---

## Problem

The sidebar currently lists all ~337 rules flat. This doesn't scale — users can't find what they need.

## Design

1. **Sidebar** shows a list of **rule categories** (not individual rules)
2. **Clicking a category** shows its rules in the detail view
3. **Rule rows in the detail view** show the information currently shown as rule detail (description, scope, correctable, severity, etc.)

## Proposed Categories (22)

Derived from the existing `Rules/` directory structure. Each category has 5–20 rules (a few at boundary).

### Formatting

| Category | Count | Source |
|----------|-------|--------|
| Blank Lines | 12 | Whitespace/VerticalSpacing |
| Spacing | 12 | Whitespace/HorizontalSpacing |
| Braces & Indentation | 7 | Whitespace/Braces |
| Punctuation & Line Endings | 11 | Whitespace/Punctuation + LineEndings |
| Line Wrapping | 19 | Multiline/* |

### Code Quality

| Category | Count | Source |
|----------|-------|--------|
| Redundant Expressions | 9 | Redundancy/Expressions |
| Redundant Syntax | 10 | Redundancy/Syntax |
| Redundant Declarations | 16 | Redundancy/Modifiers + Types |
| Redundant Visibility | 7 | Redundancy/Visibility |
| Dead Code | 12 | DeadCode/* |
| Performance | 20 | Performance/* |
| Metrics | 10 | Metrics/* |

### Language

| Category | Count | Source |
|----------|-------|--------|
| Access Control | 17 | AccessControl/* |
| Closures & Returns | 18 | ControlFlow/Closures + Returns |
| Conditionals & Patterns | 20 | ControlFlow/Conditionals + Patterns |
| Naming | 12 | Naming/* |
| Ordering | 16 | Ordering/* |
| Type Safety | 25 | TypeSafety/* |

### Ecosystem

| Category | Count | Source |
|----------|-------|--------|
| Concurrency | 11 | Modernization/Concurrency |
| Legacy Code | 17 | Modernization/Legacy |
| Foundation | 14 | Frameworks/Foundation |
| SwiftUI | 9 | Frameworks/SwiftUI |
| Documentation | 16 | Documentation/* |
| Testing | 17 | Testing/* |

**Total: 337 rules across 24 categories** (range: 7–25 per category)

## Open Questions

- Should the sidebar group categories under section headers (Formatting / Code Quality / Language / Ecosystem)?
- "Redundant *" split into 4 small categories vs 2 larger ones?
- "Type Safety" at 25 — split Optionals (8) from Types (10) + Correctness (7)?

## Tasks

- [x] Add `category` (and optional `categoryGroup`) metadata to rule model
- [x] Assign every rule a category (matching directory structure)
- [x] Replace sidebar `List` of rules with `List` of categories
- [x] Build detail view: category header + rule rows with full info
- [x] Selecting a rule row from detail navigates to rule detail (or inline expand)
- [x] Preserve search — filter should work across categories


## Summary of Changes

Added `DisplayCategory` enum (24 categories in 4 groups: Formatting, Code Quality, Language, Ecosystem) mapping from directory-based `RuleCategory` to UI-friendly groupings. Sidebar now shows category sections with icons and rule counts. Clicking a category shows its rules in the detail view with toggle, scope badge, name, auto-fix indicator, rule ID, and summary. Search and scope filter work across categories, hiding empty ones.

### Files Changed
- **New**: `Xcode/SwiftiomaticApp/Models/DisplayCategory.swift` — `CategoryGroup` + `DisplayCategory` enums with mapping from `RuleCategory`
- **New**: `Xcode/SwiftiomaticApp/Views/CategoryDetailView.swift` — detail view for a selected category
- **Modified**: `Xcode/SwiftiomaticApp/Views/ContentView.swift` — sidebar shows categories grouped by section
- **Modified**: `Xcode/SwiftiomaticApp/Views/RuleRow.swift` — richer card with toggle, badges, ID, and summary
- **Modified**: `Xcode/Swiftiomatic.xcodeproj/project.pbxproj` — new files added to project
