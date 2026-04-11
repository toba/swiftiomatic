---
# 9qw-72x
title: 'Improve rule summaries: fill empty static let summary fields'
status: completed
type: task
priority: normal
created_at: 2026-04-11T18:22:20Z
updated_at: 2026-04-11T18:55:20Z
sync:
    github:
        issue_number: "181"
        synced_at: "2026-04-11T19:12:32Z"
---

6+ rules have `static let summary = ""`. Fill them in with concise, useful descriptions.

Identified rules with empty summaries:
- `static_over_final_class`
- `non_overridable_class_declaration`
- `opening_brace`
- `contrasted_opening_brace`
- `number_separator`
- `unhandled_throwing_task`
- (scan for others)

## Tasks

- [x] Find all rules with empty summary fields (found 16)
- [x] Write concise summaries for each
- [x] Verify build passes


## Summary of Changes

Filled in 16 empty rule summaries and improved 9 existing ones that were vague or awkwardly phrased.

### 16 new summaries
- `number_separator` — Underscores should be used as thousand separators in large decimal numbers
- `unhandled_throwing_task` — Errors thrown inside a Task are silently lost unless the result is checked
- `non_overridable_class_declaration` — Use `static` or `final` instead of `class` for non-overridable members
- `superfluous_disable_command` — Disable commands for rules that didn't trigger a violation are superfluous
- `blanket_disable_command` — Disable commands should be scoped with `next`, `this`, or `previous` instead of the whole file
- `static_over_final_class` — Prefer `static` over `final class` or `class` in a final class
- `shorthand_argument` — Shorthand closure arguments (`$0`, `$1`) should be used sparingly and close to the closure opening
- `inclusive_language` — Identifiers should use inclusive language that avoids discrimination
- `unused_parameter` — Unused function parameters should be removed or replaced with `_`
- `type_name` — Type names should be alphanumeric, start uppercase, and have a reasonable length
- `contrasted_opening_brace` — Opening braces should be on a separate line from the preceding declaration
- `opening_brace` — Opening braces should be preceded by a single space and on the same line as the declaration
- `switch_case_alignment` — Case statements should vertically align with their enclosing switch's closing brace
- `colon` — Colons should have no space before and one space after
- `attribute_name_spacing` — There should be no space between an attribute or modifier and its arguments
- `attributes` — Attributes should be on their own line for functions and types, same line for variables and imports

### 9 improved summaries
- `invalid_command` — was "sm: command is invalid"
- `unused_setter_value` — was "Setter value is not used"
- `joined_default_parameter` — was "Discouraged explicit usage of the default separator"
- `file_types_order` — was "Specifies how the types within a file should be ordered."
- `type_contents_order` — was "Specifies the order of subtypes, properties, methods & more within a type."
- `xct_specific_matcher` — was "Prefer specific XCTest matchers."
- `discouraged_direct_init` — was "Discouraged direct initialization of types that can be harmful"
- `syntactic_sugar` — was "Shorthand syntactic sugar should be used, i.e. [Int] instead of Array<Int>."
- `self_binding` — was "Re-bind `self` to a consistent identifier name."

Confirmed: `summary` is the only description field on the `Rule` protocol — there is no separate `description` property. They are the same thing.
