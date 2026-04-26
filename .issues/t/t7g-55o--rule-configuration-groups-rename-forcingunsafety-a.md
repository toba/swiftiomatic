---
# t7g-55o
title: 'Rule configuration groups: rename forcing→unsafety, add memory, regroup ungrouped'
status: completed
type: task
priority: normal
created_at: 2026-04-26T00:07:47Z
updated_at: 2026-04-26T00:18:04Z
sync:
    github:
        issue_number: "440"
        synced_at: "2026-04-26T00:18:52Z"
---

See /Users/jason/.claude/plans/review-rule-configuration-groups-sharded-fox.md for the full plan.

## Tasks

- [ ] Document lineBreaks vs wrap boundary in ConfigurationGroup.swift
- [ ] Rename forcing → unsafety (enum, accessor, registry, all rule overrides, project JSON, schema.json)
- [ ] Verify actual ungrouped rule set by inspecting each rule file
- [ ] Add new memory group (enum case + accessor)
- [ ] Move weakDelegates, strongOutlets, deinitObserverRemoval, delegateProtocolRequiresAnyObject, preferWeakCapture, retainNotificationObserver to memory
- [ ] Move fileHeader → comments
- [ ] Move emptyExtensions, preferSingleLinePropertyGetter → declarations
- [ ] Move unusedArguments, noBacktickedSelf, noFallThroughOnlyCases → redundancies
- [ ] Move leadingDotOperators, preferExplicitFalse, preferAssertionFailure, preferEnvironmentEntry, preferWhereClausesInForLoops → idioms
- [ ] Move noImplicitlyUnwrappedOptionals, noOptionalBool, noOptionalCollection, preferFailableStringInit, preferNonOptionalDataInit → types
- [ ] Move typedCatchError → unsafety
- [ ] Regenerate schema.json
- [ ] Update project configuration JSON
- [ ] Build and test pass via xc-mcp



## Summary of Changes

- **ConfigurationGroup.swift**: renamed `forcing` → `unsafety`; added `memory` group; added doc comments distinguishing `lineBreaks` (where breaks happen) vs `wrap` (how multi-line constructs format).
- **Rule directories renamed**: `Forcing` → `Unsafety`, `Capitalization` → `Naming`, `Redundant` → `Redundancies`. Created `Memory/`.
- **22 ungrouped rules assigned to groups** (added `override class var group` and moved into matching directories):
  - **types**: NoImplicitlyUnwrappedOptionals, NoOptionalBool, NoOptionalCollection, PreferFailableStringInit, PreferNonOptionalDataInit
  - **declarations**: EmptyExtensions, PreferSingleLinePropertyGetter
  - **comments**: FileHeader
  - **redundancies**: NoBacktickedSelf, NoFallThroughOnlyCases, UnusedArguments
  - **idioms**: LeadingDotOperators, PreferAssertionFailure, PreferEnvironmentEntry, PreferExplicitFalse, PreferWhereClausesInForLoops
  - **memory**: WeakDelegates, StrongOutlets, DeinitObserverRemoval, DelegateProtocolRequiresAnyObject, PreferWeakCapture, RetainNotificationObserver (moved from idioms)
  - **unsafety**: TypedCatchError (alongside the renamed NoForce* trio)
- **Root-level files moved into matching directories**: ASCIIIdentifiers, NoLeadingUnderscores → Naming/; NoSemicolons → Redundancies/; PatternLetPlacement, FullyIndirectEnum → Hoist/; etc.
- **swiftiomatic.json**: top-level `forcing` renamed to `unsafety`; new `memory` group added; all formerly-root rules moved into their proper groups; `retainNotificationObserver` moved from idioms to memory. Lint/rewrite values preserved.
- **schema.json**: regenerated via `swift run Generator`.
- **ConfigurationUpdateTests**: updated `detectsUngroupedRulePlacedInGroup` → `detectsRulePlacedInWrongGroup` (every rule now belongs to a group).

All 2940 tests pass.
