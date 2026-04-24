---
# p85-z9w
title: Eliminate swift-syntax compilation in CI
status: completed
type: task
priority: high
created_at: 2026-04-24T18:22:37Z
updated_at: 2026-04-24T22:03:47Z
sync:
    github:
        issue_number: "373"
        synced_at: "2026-04-24T22:30:44Z"
---

swift-syntax compiles from source every CI run (~5 min). Investigate two approaches to eliminate this.

## Options

- [x] **Option A: Toolchain-bundled swift-syntax** — ❌ NOT VIABLE. Toolchain's SwiftSyntax uses `-module-abi-name CompilerSwiftSyntax` and `-package-name Toolchain`, making it ABI-incompatible with the open-source swift-syntax. No SPM flag exists to remap this.
- [x] **Option B: Self-hosted artifact bundle** — ❌ IMPRACTICAL. SPM `.binaryTarget` maps to a single framework per target. We depend on 5+ swift-syntax modules (SwiftSyntax, SwiftParser, SwiftOperators, etc.). The `_SwiftSyntaxDynamic` product doesn't include SwiftOperators. Merging into an uber-framework loses module boundaries. High maintenance burden for marginal gain.

## Notes

- Option A preferred if API delta between 603.0.1 and 6.3.1 is manageable
- Commit `fafcd22b` pinned to 603.0.1 and disabled modifiers guard pending 604.0.0 — check if resolved in 6.3.1
- Current workaround: `swift test -c release` shares artifacts with release step (cuts ~50%)


## Investigation Results (2026-04-24)

### Option A: Toolchain swift-syntax
Inspected `/Applications/Xcode.app/.../swift/host/SwiftSyntax.swiftmodule/arm64-apple-macos.swiftinterface`:
```
-module-abi-name CompilerSwiftSyntax
-package-name Toolchain
-user-module-version 6.3.1.1.2
```
The toolchain's swift-syntax is ABI-namespaced for the compiler's internal use. Consumer packages cannot link against it.

### Option B: Artifact bundle
The SwiftFormat reference (`spm-artifact-bundle.sh`) packages the **executable**, not swift-syntax. Packaging swift-syntax as a binary dependency would require building 5+ XCFrameworks and maintaining a custom build pipeline.

### Recommended: Better CI caching
The current cache key `spm-${{ runner.os }}-${{ hashFiles('Package.resolved') }}` misses the Xcode version. Add `${{ env.XCODE_VERSION }}` to the key. Also add `swift package resolve` as a separate step to populate the dependency cache before building.

### TODO
- [x] Add Xcode version to SPM cache key
- [x] Add `swift package resolve` step before build
- [x] Add CI workflow for push/PR (`ci.yml`)
