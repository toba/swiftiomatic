---
# lwe-82h
title: 'AttributePlacementRule: add inline_when_fits option'
status: completed
type: feature
priority: normal
created_at: 2026-04-11T23:10:36Z
updated_at: 2026-04-11T23:32:13Z
sync:
    github:
        issue_number: "199"
        synced_at: "2026-04-11T23:48:39Z"
---

## Context

`AttributePlacementRule` currently enforces that attributes go on their own line for functions/types and on the same line for variables/imports. It has `always_on_same_line` / `always_on_new_line` override lists but no width-aware mode.

## Problem

Simple, argument-less attributes like `@Test` waste vertical space when the combined line easily fits:

```swift
// before
@Test
func `Fails when folder does not exist`() throws {

// after
@Test func `Fails when folder does not exist`() throws {
```

## Solution

Add an `inline_when_fits` option (default `false`) to `AttributePlacementRule`:

- When enabled, simple attributes (no arguments) on functions/types get inlined onto the declaration line if the combined result fits within `max_width`
- Attributes with arguments (e.g. `@available(...)`, `@Test(.tags(...))`) stay on their own line regardless
- Multiple attributes stay on their own lines regardless (only single-attribute inlining)
- Respects `always_on_new_line` overrides — those attributes never get inlined

## Implementation

- [x] Conform `AttributePlacementRule` to `FormatAwareRule` with `formatConfigKeys: ["max_width"]`
- [x] Add `inline_when_fits` option to `AttributePlacementOptions` (default `false`)
- [x] Add `max_width` option to `AttributePlacementOptions` (injected from format config)
- [x] Update visitor to check combined line width when `inline_when_fits` is enabled
- [x] Make the rule correctable — visitor-based corrections (no Rewriter needed)
- [x] Add correction examples for the new option
- [x] Update rule rationale documentation

## Config example

```yaml
rules:
  config:
    attribute_placement:
      inline_when_fits: true

format:
  max_width: 120
```


## Summary of Changes

- Added `inline_when_fits` option (default `false`) and `max_width` option to `AttributePlacementOptions`
- Made the rule correctable with visitor-based corrections (no Rewriter)
- Added `FormatAwareRule` conformance to inherit global `format.max_width`
- Added correction examples that test the new option via `configuration:` parameter
- Updated `/rule` skill with swift-syntax API reference, common patterns, and key file paths
