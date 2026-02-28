---
# 9q3-qlh
title: Consolidate and standardize rules across analyze, format, and lint
status: draft
type: epic
priority: normal
created_at: 2026-02-27T23:31:20Z
updated_at: 2026-02-28T00:05:23Z
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

## Implementation Plan

### Phase 0: Rename Scan → Suggest

Rename the `Scan` command to `Suggest` throughout:
- `Sources/Swiftiomatic/swiftiomatic.swift`: rename struct `Scan` → `Suggest`, update subcommands array and defaultSubcommand

### Phase 1: Internal Suggest Deduplication

#### 1a. Remove `withObservationTracking` from Swift62ModernizationCheck
**File:** `Sources/Analysis/Checks/Swift62ModernizationCheck.swift`
Delete lines 22-32 (the `withObservationTracking` block). Keep in `ObservationPitfallsCheck` (§7) which is the natural home.

#### 1b. Remove fire-and-forget Task detection from AgentReviewCheck
**File:** `Sources/Analysis/Checks/AgentReviewCheck.swift`
Remove lines 6-36 (`Task`/`Task.detached` detection) and lines 72-77 (`.onAppear + Task` stub). `FireAndForgetTaskCheck` is a strict superset with scope-aware severity. Keep: `.absoluteString` (38-47), `MemberAccessExprSyntax` (54-70), Error enum (79-97), `nonisolated(unsafe)` (99-116).

### Phase 2: Unified Config Schema

#### 2a. Extend SwiftiomaticConfig with suggest and lint sections
**File:** `Sources/Swiftiomatic/Config.swift`
Add `SuggestConfig` (categories, minConfidence, minSeverity, sourcekit, exclude) and `LintConfig` (disabledRules, optInRules, analyzerRules, exclude, ruleConfig passthrough). Parse from `suggest:` and `lint:` YAML keys. Rename existing format-only fields into `FormatConfig` sub-struct.

#### 2b. Wire SuggestConfig into the Suggest command
**File:** `Sources/Swiftiomatic/swiftiomatic.swift`
Load `.swiftiomatic.yaml`, apply `suggest:` config as defaults, CLI flags override. Add `--config` option.

#### 2c. Wire LintConfig via .swiftlint.yml bridge
**File:** `Sources/Swiftiomatic/LintCommand.swift`
When `.swiftiomatic.yaml` has a `lint:` section, generate a temporary `.swiftlint.yml` and pass as `configurationFiles`. Fall back to native `.swiftlint.yml` if no section.

### Phase 3: Format/Lint Overlap Suppression

#### 3a. Define format-owned lint deny-list
Constant set of lint rule IDs that format owns (forcibly disabled when bridging):
`trailing_comma, sorted_imports, modifier_order, redundant_self, duplicate_imports, prefer_key_path, void_return, implicit_return, redundant_type_annotation, async_without_await`

#### 3b. Update .swiftlint.yml defaults
Remove from `opt_in_rules`: `async_without_await`, `redundant_self`, `prefer_key_path`, `redundant_type_annotation`. Add to `disabled_rules`.

#### 3c. Dead code ownership (no code changes, document only)
- **Suggest** (`DeadSymbolsCheck`): authoritative for cross-file USR-based dead symbol detection
- **Lint** (`unused_declaration`): keep as analyzer rule for single-file SourceKit precision
- **Format** (`unusedPrivateDeclarations`): stays disabled by default (token-based, weakest)

### Phase 4: Documentation
Update CLAUDE.md with Rule Ownership section.

### Overlap Analysis Reference

**Format ↔ Lint overlaps (format is authoritative, auto-fixes):**
| Concept | Format Rule | Lint Rule |
|---------|------------|-----------|
| Trailing commas | trailingCommas | trailing_comma |
| Sorted imports | sortImports | sorted_imports |
| Modifier order | modifierOrder | modifier_order |
| Redundant self | redundantSelf | redundant_self |
| Duplicate imports | duplicateImports | duplicate_imports |
| Prefer key path | preferKeyPath | prefer_key_path |
| Void return | redundantVoidReturnType + void | void_return |
| Implicit return | redundantReturn | implicit_return |
| Redundant type | redundantType | redundant_type_annotation |
| Redundant async | redundantAsync | async_without_await |

**Internal suggest overlaps (deduplicate):**
- `withObservationTracking`: ObservationPitfallsCheck (§7) ✓ keeps, Swift62ModernizationCheck (§4) ✗ removes
- Fire-and-forget Task: FireAndForgetTaskCheck ✓ keeps (scope-aware), AgentReviewCheck ✗ removes (basic subset)
