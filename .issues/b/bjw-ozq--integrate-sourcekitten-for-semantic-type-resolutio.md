---
# bjw-ozq
title: Integrate SourceKitten for semantic type resolution
status: completed
type: feature
priority: normal
created_at: 2026-02-27T22:39:11Z
updated_at: 2026-02-27T22:47:37Z
sync:
    github:
        issue_number: "5"
        synced_at: "2026-03-01T01:01:29Z"
---

Add SourceKitService target with TypeResolver protocol and SourceKittenResolver implementation. Thread resolver through Analyzer → BaseCheck. Add CLI flags --sourcekit, --project-root, --compiler-args.

## Summary of Changes

### New Target: SourceKitService
- `TypeResolver` protocol + value-type models (`ResolvedType`, `FileIndex`, `IndexSymbol`, `ExpressionTypeInfo`)
- `SourceKittenResolver`: wraps cursorinfo, index, expression-type requests with caching
- `NullResolver`: no-op fallback for syntax-only mode
- Compiles with `.swiftLanguageMode(.v5)` since SourceKittenFramework isn't Swift 6 ready

### Enhanced Checks (collect-then-resolve pattern)
- **DeadSymbolsCheck**: USR-based declaration/reference matching via file indexing
- **TypedThrowsCheck**: resolves thrown variable types via cursorinfo
- **AnyEliminationCheck**: detects type aliases resolving to `Any`
- **NamingHeuristicsCheck**: detects inferred Bool types via expression-type request
- **ConcurrencyModernizationCheck**: verifies DispatchQueue identity, upgrades confidence

### CLI Flags
- `--sourcekit`: opt-in to semantic analysis (default off)
- `--project-root`: SPM root for compiler arg discovery
- `--compiler-args`: explicit compiler arguments override

### Tests
- 4 new mock-based tests for TypeResolver integration
- All 12 tests pass (8 existing + 4 new)
- Zero behavior change when `typeResolver = nil`
