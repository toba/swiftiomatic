---
# 9q3-qlh
title: Consolidate and standardize rules across analyze, format, and lint
status: draft
type: epic
created_at: 2026-02-27T23:31:20Z
updated_at: 2026-02-27T23:31:20Z
---

Three subsystems (analyze/scan, format, lint) have grown independently with overlapping rules, separate config systems, and no deduplication. This epic covers unifying them into a coherent whole.

## Problem Areas

### 1. Duplicate detection (same concept, multiple engines)
- **Dead code**: `DeadSymbolsCheck` (analyze, cross-file USR), `unusedPrivateDeclarations` (format, single-file token), `unused_declaration` (lint, compiler-backed) — all three can fire on the same symbol
- **Redundant async**: `redundantAsync` (format) vs `async_without_await` (lint) — same semantic concept
- **Force unwrap/try**: format has `noForceUnwrapInTests`/`noForceTryInTests` (disabled), lint has `force_unwrapping`/`force_try` (enabled)
- **Trailing commas**: format's `trailingCommas` (enabled) vs lint's `trailing_comma` (disabled in .swiftlint.yml) — coordinated by convention only
- **Sorted imports**: format's `sortImports` vs lint's `sorted_imports`
- **Modifier order**: format's `modifierOrder` vs lint's `modifier_order`
- **Redundant self**: format's `redundantSelf` vs lint's `redundant_self`
- **Duplicate imports**: format's `duplicateImports` vs lint's `duplicate_imports`
- **Prefer key path**: format's `preferKeyPath` (enabled) vs lint's `prefer_key_path` (opt-in)
- **Void return**: format's `redundantVoidReturnType`/`void` vs lint's `void_return`
- **Implicit return**: format's `redundantReturn` vs lint's `implicit_return`
- **Redundant type annotation**: format's `redundantType` vs lint's `redundant_type_annotation`

### 2. Internal analyze overlaps
- `withObservationTracking` flagged by both `ObservationPitfallsCheck` (§7) and `Swift62ModernizationCheck` (§4)
- `Task {}` flagged by both `AgentReviewCheck` and `FireAndForgetTaskCheck` in the same category

### 3. Three separate config systems
- `scan`: CLI flags only, no config file
- `format`: `.swiftiomatic.yaml` (`format:` key)
- `lint`: `.swiftlint.yml` (native SwiftLint format)

No unified config governs all three.

## Tasks

- [ ] Audit all overlapping rules and decide ownership (which subsystem is authoritative for each concept)
- [ ] For format↔lint overlaps, disable the non-authoritative side and document why
- [ ] Deduplicate internal analyze overlaps (`withObservationTracking`, `Task {}`)
- [ ] Design unified config schema in `.swiftiomatic.yaml` that covers all three subsystems
- [ ] Add `scan` config support (categories, confidence, severity) to `.swiftiomatic.yaml`
- [ ] Bridge lint config into `.swiftiomatic.yaml` (translate to/from `.swiftlint.yml` internally)
- [ ] Add a combined `check` or `all` subcommand that runs all three with deduplication
- [ ] Document the rule landscape: which rules live where, which are authoritative
