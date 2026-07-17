---
# dzb-k32
title: 'Port swift-format ImportsAnyTestingLibrary: relax test-gated rules inside Swift Testing files'
status: completed
type: task
priority: high
created_at: 2026-07-17T17:47:39Z
updated_at: 2026-07-17T17:59:57Z
sync:
    github:
        issue_number: "754"
        synced_at: "2026-07-17T18:05:05Z"
---

Upstream swiftlang/swift-format reworked `ImportsXCTestVisitor` into `ImportsAnyTestingLibrary` (PR #1244, #1247; closes #1243; SHAs 58aa8bd, 9e228b7).

## Upstream change
The old visitor only detected XCTest imports. It is renamed to `ImportsAnyTestingLibrary` and now recognizes **both XCTest and Swift Testing**, with the supported-module list stored in an extensible property on the visitor.

This gates four rules that previously relaxed their checks only inside XCTest files. They now also relax inside Swift Testing files:
- NeverUseForceTry
- NeverForceUnwrap
- NeverUseImplicitlyUnwrappedOptionals
- AlwaysUseLowerCamelCase

Files touched upstream: `Sources/SwiftFormat/Core/Context.swift`, new `Sources/SwiftFormat/Core/ImportsAnyTestingLibrary.swift` (replaces `ImportsXCTestVisitor.swift`), and the four rule files.

## Task
- [ ] Inspect Swiftiomatic's `TestSuiteDetection` / test-file gating and the local equivalents of the four rules above.
- [ ] Determine whether our gating already relaxes inside Swift Testing files or only XCTest.
- [ ] If XCTest-only, extend detection to recognize Swift Testing imports (mirror the extensible module-list approach).
- [ ] Add/confirm tests: force-try, force-unwrap, IUO, and lowerCamelCase should be relaxed inside a Swift Testing file (`import Testing`), matching the XCTest behavior.

Reference clone: `~/Developer/swiftiomatic-ref/swift-format` (check the cited SHAs).

## Summary of Changes

Ported upstream swift-format PR #1244/#1247 (`ImportsXCTestVisitor` → `ImportsAnyTestingLibrary`). Swiftiomatic's test-file gate now treats **any supported test library** as test code, not just XCTest.

### Detection
- Renamed `Sources/SwiftiomaticKit/Syntax/ImportsXCTestVisitor.swift` → `ImportsAnyTestLibrary.swift`.
- Added extensible module list `supportedTestLibraryModuleNames = ["XCTest", "Testing"]`.
- Renamed `setImportsXCTest` → `setImportsAnyTestLibrary`.
- `#if`-conditional imports are covered for free — the visitor walks the whole tree (unlike upstream, which had to add explicit `ifConfigDecl` recursion because it iterates statements).

### Context (`Support/Context.swift`)
- Enum `XCTestImportState` → `AnyTestImportState`; cases → `importsTestLibrary` / `doesNotImportTestLibrary` (fixed upstream's `importsATestLirary` typo).
- Field `importsXCTest` → `importsAnyTestLibrary`. This rename matters: leaving the field named `importsXCTest` while it becomes true for `Testing` files is a footgun — `NoForceTry`/`NoForceUnwrap` read it right beside an `XCTestCase` inheritance check.

### Behavioral changes (the two rules that were XCTest-only)
- **`NoImplicitlyUnwrappedOptionals`**: file-level relaxation now fires for Swift Testing files (`import Testing` → `var s: String!` no longer flagged).
- **`RequireCamelCaseIdentifiers`**: `collectTestMethods` now runs in Swift Testing files, so `test`-prefixed underscore method names get the same exemption XCTest files receive.

### No behavioral change (already ahead of upstream)
- `NoForceTry`, `NoForceUnwrap` already detected Swift Testing independently (`importsTesting` + `@Test`). Their `== .importsTestLibrary` guard is narrowed by an `XCTestCase` inheritance check, so broadening detection is inert for them.
- Also updated call sites in `RequireTestFnPrefixOrAttribute`, `TestSuiteDetection` (`TestContextTracker`), and `Rewriter/SourceFile.swift`.

### Tests
- Renamed `ImportsXCTestVisitorTests` → `ImportsAnyTestLibraryTests`; rewrote as a parameterized suite over every supported module × {direct, decl, conditional, nested, else-branch} (mirrors upstream `SetImportsAnyTestLibraryTests`).
- Added `NoImplicitlyUnwrappedOptionalsTests.ignoreSwiftTestingCode`.
- Added `RequireCamelCaseIdentifiersTests.ignoresUnderscoresInTestNamesWithSwiftTesting`.
- Verified via xc-swift: 17 pass (detection + 2 new rule tests); 59 pass (force-rule + RequireTestFnPrefix regression); full test-target compile succeeds (code-gen plugin regenerated cleanly).
