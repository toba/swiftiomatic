---
# 71r-8n7
title: RemoveRedundantSelf strips required self in extension property accessor
status: completed
type: bug
priority: high
created_at: 2026-05-01T23:18:01Z
updated_at: 2026-05-01T23:30:48Z
sync:
    github:
        issue_number: "616"
        synced_at: "2026-05-02T00:08:55Z"
---

## Problem

`RemoveRedundantSelf` removes `self.` in cases where it is required, producing code that fails to compile.

## Repro

```swift
import Core
import SwiftUI

#if os(macOS)

typealias PlatformAttributes = ScopedAttributeContainer<AttributeScopes.AppKitAttributes>

extension AttributedSubstring: PlatformAttributeAccessor {
    var platform: PlatformAttributes {
        self.appKit
    }
}
#endif
```

After formatting, `self.appKit` becomes `appKit`, and the compiler errors:

> Cannot find 'appKit' in scope

`appKit` here is a member exposed via `AttributedSubstring`'s dynamic member lookup / scoped attribute container — it is not a free symbol in scope, so `self.` is required.

## Workaround

`// swiftformat:disable redundantSelf` (shown in screenshot) — but our directive is `// sm:ignore`, and this should not require a directive at all.

## Expected

`RemoveRedundantSelf` must not strip `self.` when the member is only resolvable through `self` (e.g. `@dynamicMemberLookup`, scoped attribute containers, or any case where the bare identifier is not in scope). Conservatively: if the type conforms to `@dynamicMemberLookup` or the extended type is a known dynamic-member-lookup type (`AttributedString`, `AttributedSubstring`, `ScopedAttributeContainer`, SwiftUI `Binding`, etc.), preserve `self.`.

## Tasks

- [x] Add failing test reproducing the strip on `AttributedSubstring` extension
- [x] Detect `@dynamicMemberLookup` context and skip the rewrite
- [x] Verify against `Binding`, `AttributedString`, `AttributedSubstring` cases
- [x] Run full suite to confirm no regressions



## Summary of Changes

**`Sources/SwiftiomaticKit/Rules/Redundancies/DropRedundantSelf.swift`**
- Added `dynamicLookupStack: [Bool]` to `State` plus `inDynamicLookupScope` accessor.
- Added `knownDynamicMemberLookupTypes` allowlist (`AttributedString`, `AttributedSubstring`, `ScopedAttributeContainer`, `Binding`).
- Added `hasDynamicMemberLookup(_:)` and `extensionExtendsKnownDynamic(_:)` helpers.
- Each scope-decl `willEnter` (struct/class/actor/enum/extension) now pushes a flag onto `dynamicLookupStack`; the extension hook also checks the allowlist.
- `transform` returns the node unchanged when `inDynamicLookupScope` is true.

**`Tests/SwiftiomaticTests/Rules/DropRedundantSelfTests.swift`**
- Added `keepSelfInExtensionOnKnownDynamicMemberLookupType` (the original repro).
- Added `keepSelfInTypeDeclaredDynamicMemberLookup` for in-source `@dynamicMemberLookup` types.
- Added `keepSelfInExtensionOnSwiftUIBinding` for the SwiftUI `Binding` case.
- Added `stillStripsInExtensionOnNormalType` regression guard.

## Verification
- `DropRedundantSelfTests`: 55 passed, 0 failed.
- Full suite: 3167 passed; 4 failures are pre-existing layout/collection-literal failures (tracked separately as `zbo-eta`) and unrelated to this change.
