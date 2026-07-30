---
# x17-ayx
title: Migrate Parsing.swift to swift-syntax LanguageFeatures naming
status: deferred
type: task
priority: deferred
created_at: 2026-07-26T06:55:02Z
updated_at: 2026-07-26T06:56:29Z
sync:
    github:
        issue_number: "758"
        synced_at: "2026-07-30T03:27:16Z"
---

Upstream swiftlang/swift-syntax renamed `Parser.ExperimentalFeatures` → `Parser.LanguageFeatures` and the `experimentalFeatures:` parameter/property → `languageFeatures:` (commit e3603f1a, 2026-07-22), and made the type public while collapsing the SPI overloads into a single defaulted argument (commit 80563065, 2026-07-06). Deprecated `@_spi(ExperimentalLanguageFeatures)` compatibility shims (an `ExperimentalFeatures` typealias plus `experimentalFeatures:` overloads on `Parser.init`/`Parser.parse`) keep existing clients building for now.

We use exactly this surface in `Sources/SwiftiomaticKit/Syntax/Parsing.swift`:
- `Parser.ExperimentalFeatures` (var declaration, ~line 46)
- `Parser.ExperimentalFeatures(name:)` (feature lookup, ~line 49)
- `Parser.parse(source:experimentalFeatures:)` (~line 57)

Nothing breaks yet thanks to the shims, but once we bump the swift-syntax pin we will get deprecation warnings.

## Todo
- [ ] Bump swift-syntax pin to include the rename
- [ ] Rename local + `Parser.ExperimentalFeatures` → `Parser.LanguageFeatures` in Parsing.swift
- [ ] Update `Parser.parse(source:experimentalFeatures:)` call to `languageFeatures:`
- [ ] Update doc comments referencing `Parser.ExperimentalFeatures` in Parsing.swift, RewriteCoordinator.swift, LintCoordinator.swift
- [ ] Confirm the `@_spi(ExperimentalLanguageFeatures)` import is still needed (individual flags remain SPI)
- [ ] Build + full test suite to confirm no regressions

Source: cite review 2026-07-26.

## Deferral Notes

Cannot proceed yet: the rename is **only on swift-syntax `main`** and is not in any tagged release. Our pin is `exact: "603.0.1"` (Package.swift:18, resolved revision `9de99a78`), which predates the rename — its `Sources/SwiftParser/generated/ExperimentalFeatures.swift` still declares `public struct ExperimentalFeatures` and `Parser.parse` only takes `experimentalFeatures:`. There is **no `LanguageFeatures` symbol and no compatibility shim** in 603.0.1.

Consequences:
- Migrating the code now would not compile — `Parser.LanguageFeatures` / `languageFeatures:` don't exist in the pinned version.
- The only way to get the new API today is to point the pin at the `main` branch, which is a moving, untagged target aligned to no toolchain release. That would drag in every other unrelated breaking change across the ~50 changed upstream files — out of scope and destabilizing for a naming migration.

Blocked on: swift-syntax cutting a tagged release (likely a 60x line) that contains commit `e3603f1a`. Once such a tag exists:
1. Bump the `exact:` pin in Package.swift to that release and re-resolve.
2. Apply the migration steps in the Todo above (the deprecated `experimentalFeatures:` shims upstream mean the build keeps working even before renaming, so it can be done incrementally).
3. Build + full test suite.

Re-open (set back to `ready`) when a release with the rename is available. No source changes were made.
